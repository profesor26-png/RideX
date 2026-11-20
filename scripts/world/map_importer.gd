extends Node3D
class_name MapImporter
## Projeto Grau 2 (Unity) haritasini Godot'a kurar.
## map_manifest.json + OBJ (.msh) mesh'lerini okur, dunya matrislerini uygular.
## Unity sol-elli -> Godot sag-elli: Z flip + winding ters + matris konjugasyonu.

@export var base_path: String = "res://assets/projeto/"
@export var max_objects: int = 0
@export var flip_v: bool = true
@export var verbose: bool = false
@export var collision: bool = false
@export var collision_min_size: float = 1.5
@export var static_only: bool = false
@export var world_scale: float = 1.0
@export var unshaded: bool = false

var stats := {"objects": 0, "meshes_loaded": 0, "materials": 0, "skipped": 0, "colliders": 0}
var _mesh_cache := {}
var _mat_cache := {}
var _matdefs := {}
var _tex_cache := {}

const SIGN := [1.0, 1.0, -1.0, 1.0]


func build() -> Dictionary:
    var objs := _load_objects()
    if objs.is_empty():
        return stats
    var limit := objs.size() if max_objects <= 0 else mini(max_objects, objs.size())
    for i in range(limit):
        if not _spawn_one(objs[i], i):
            stats["skipped"] += 1
    if verbose:
        print("[map] built: ", stats)
    return stats


func build_async(on_progress: Callable) -> Dictionary:
    var objs := _load_objects()
    if objs.is_empty():
        return stats
    var limit := objs.size() if max_objects <= 0 else mini(max_objects, objs.size())
    for i in range(limit):
        if not _spawn_one(objs[i], i):
            stats["skipped"] += 1
        if i % 20 == 0 or i == limit - 1:
            if on_progress.is_valid():
                on_progress.call(float(i + 1) / float(limit), i + 1, limit)
            await get_tree().process_frame
    if verbose:
        print("[map] built: ", stats)
    return stats


func _load_objects() -> Array:
    var manifest_path := base_path + "map_manifest.json"
    if not FileAccess.file_exists(manifest_path):
        push_error("manifest yok: " + manifest_path)
        return []
    var txt := FileAccess.get_file_as_string(manifest_path)
    var data = JSON.parse_string(txt)
    if data == null or not data.has("objects"):
        push_error("manifest parse hatasi")
        return []
    _load_matdefs()
    return data["objects"]


func _spawn_one(o: Dictionary, i: int) -> bool:
    if not bool(o.get("enabled", true)):
        return false
    var mesh_file: String = str(o.get("mesh", ""))
    if mesh_file == "":
        return false
    if static_only and not mesh_file.begins_with("Combined_Mesh"):
        return false
    var mesh := _get_mesh(mesh_file)
    if mesh == null:
        return false
    var xform := _to_transform(o.get("m", []))
    var scv := xform.basis.get_scale()
    var s := maxf(scv.x, maxf(scv.y, scv.z))
    if s > 2.0:
        xform.basis = xform.basis * (1.0 / s)
    var mi := MeshInstance3D.new()
    mi.name = _sanitize(str(o.get("name", "obj"))) + "_%d" % i
    mi.mesh = mesh
    mi.transform = xform
    mi.visibility_range_end = 1200.0
    mi.visibility_range_end_margin = 100.0
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mi.material_override = _get_material(o.get("materials", []))
    mi.set_meta("city", mesh_file.begins_with("Combined_Mesh"))
    add_child(mi)
    stats["objects"] += 1
    if collision:
        var ab := mi.get_aabb()
        var sz := ab.size
        if maxf(sz.x, maxf(sz.y, sz.z)) >= collision_min_size:
            mi.create_trimesh_collision()
            stats["colliders"] += 1
    return true


func _get_mesh(file: String) -> Mesh:
    if _mesh_cache.has(file):
        return _mesh_cache[file]
    var path := base_path + "assets/meshes/" + file
    var m := _parse_obj(path)
    _mesh_cache[file] = m
    if m != null:
        stats["meshes_loaded"] += 1
    return m


func _parse_obj(path: String) -> Mesh:
    if not FileAccess.file_exists(path):
        return null
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var verts := PackedVector3Array()
    var norms := PackedVector3Array()
    var uvs := PackedVector2Array()
    var idx := PackedInt32Array()

    while not f.eof_reached():
        var line := f.get_line()
        if line.length() < 3:
            continue
        match line.substr(0, 2):
            "v ":
                var p := line.split(" ", false)
                if p.size() >= 4:
                    verts.append(Vector3(float(p[1]), float(p[2]), -float(p[3])))
            "vn":
                var p := line.split(" ", false)
                if p.size() >= 4:
                    norms.append(Vector3(float(p[1]), float(p[2]), -float(p[3])))
            "vt":
                var p := line.split(" ", false)
                if p.size() >= 3:
                    var vv := float(p[2])
                    if flip_v:
                        vv = 1.0 - vv
                    uvs.append(Vector2(float(p[1]), vv))
            "f ":
                var p := line.split(" ", false)
                if p.size() >= 4:
                    var a := _vi(p[1])
                    var b := _vi(p[2])
                    var c := _vi(p[3])
                    idx.append(a); idx.append(b); idx.append(c)
                    if p.size() >= 5:
                        var d := _vi(p[4])
                        idx.append(a); idx.append(c); idx.append(d)
    f.close()

    if verts.is_empty() or idx.is_empty():
        return null

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_INDEX] = idx
    if norms.size() == verts.size():
        arrays[Mesh.ARRAY_NORMAL] = norms
    if uvs.size() == verts.size():
        arrays[Mesh.ARRAY_TEX_UV] = uvs

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh


func _vi(tok: String) -> int:
    var s := tok
    var slash := s.find("/")
    if slash >= 0:
        s = s.substr(0, slash)
    return int(s) - 1


func _to_transform(flat) -> Transform3D:
    if typeof(flat) != TYPE_ARRAY or flat.size() < 16:
        return Transform3D.IDENTITY
    var mm := []
    for i in range(4):
        var row := []
        for j in range(4):
            row.append(float(flat[i * 4 + j]) * SIGN[i] * SIGN[j])
        mm.append(row)
    var x := Vector3(mm[0][0], mm[1][0], mm[2][0])
    var y := Vector3(mm[0][1], mm[1][1], mm[2][1])
    var z := Vector3(mm[0][2], mm[1][2], mm[2][2])
    var o := Vector3(mm[0][3], mm[1][3], mm[2][3]) * world_scale
    return Transform3D(Basis(x, y, z) * world_scale, o)


func _load_matdefs() -> void:
    var p := base_path + "materials.json"
    if not FileAccess.file_exists(p):
        return
    var d = JSON.parse_string(FileAccess.get_file_as_string(p))
    if d is Dictionary:
        _matdefs = d


func _get_texture(fn: String) -> Texture2D:
    if _tex_cache.has(fn):
        return _tex_cache[fn]
    var path := base_path + "assets/textures/" + fn
    var tex: Texture2D = null
    if ResourceLoader.exists(path):
        tex = load(path)
    elif FileAccess.file_exists(path):
        var img := Image.new()
        if img.load(path) == OK:
            tex = ImageTexture.create_from_image(img)
    _tex_cache[fn] = tex
    return tex


func _get_material(names) -> Material:
    var key := "default"
    if typeof(names) == TYPE_ARRAY and names.size() > 0:
        key = str(names[0])
    if _mat_cache.has(key):
        return _mat_cache[key]

    var mat := StandardMaterial3D.new()
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    var d = _matdefs.get(key, {})
    if d is Dictionary and d.size() > 0:
        var col = d.get("color", [0.72, 0.72, 0.72, 1.0])
        if typeof(col) == TYPE_ARRAY and col.size() >= 4:
            mat.albedo_color = Color(float(col[0]), float(col[1]), float(col[2]), float(col[3]))
        mat.metallic = float(d.get("metallic", 0.0))
        mat.roughness = float(d.get("roughness", 0.85))
        var tfn := str(d.get("tex", ""))
        if tfn != "":
            var tex := _get_texture(tfn)
            if tex != null:
                mat.albedo_texture = tex
    else:
        mat.albedo_color = _color_from(key)
        mat.roughness = 0.9
        mat.metallic = 0.0

    _mat_cache[key] = mat
    stats["materials"] += 1
    return mat


func _color_from(s: String) -> Color:
    var h := 0
    for i in range(s.length()):
        h = (h * 31 + s.unicode_at(i)) & 0xffffff
    return Color.from_hsv(float(h % 360) / 360.0, 0.45, 0.78)


func _sanitize(s: String) -> String:
    var out := ""
    for i in range(s.length()):
        var c := s[i]
        if c == "/" or c == ":" or c == "." or c == " " or c == "\\":
            out += "_"
        else:
            out += c
    return out.substr(0, 64) if out.length() > 0 else "obj"
