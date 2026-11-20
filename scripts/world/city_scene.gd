extends Node3D
## AssetRipper'in glTF sahnesini (Demo Scene.glb) yukler: dogru transform/materyal.

func _ready() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.9
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -35, 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = false
    add_child(sun)

    var ps = load("res://assets/scene/demo.glb")
    if ps == null:
        Log.error("city", "demo.glb yuklenemedi")
        return
    var root = ps.instantiate()
    add_child(root)

    var pts: Array = []
    var meshes := 0
    var stack: Array = [root]
    while not stack.is_empty():
        var n = stack.pop_back()
        if n is MeshInstance3D:
            meshes += 1
            var wb: AABB = n.global_transform * n.get_aabb()
            var mx := maxf(wb.size.x, maxf(wb.size.y, wb.size.z))
            if mx > 2500.0:
                n.visible = false
            else:
                n.visibility_range_end = 8000.0
                n.visibility_range_end_margin = 500.0
                n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                pts.append(n.global_position)
        for c in n.get_children():
            stack.append(c)

    var cam := Camera3D.new()
    cam.fov = 70.0
    cam.near = 0.1
    cam.far = 30000.0
    cam.set_script(load("res://scripts/world/free_fly.gd"))
    add_child(cam)

    if pts.is_empty():
        cam.position = Vector3(0, 200, 400)
        cam.rotation = Vector3(-0.4, 0, 0)
        Log.info("city", "mesh yok")
    else:
        var xs: Array = []
        var ys: Array = []
        var zs: Array = []
        for p in pts:
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
        xs.sort(); ys.sort(); zs.sort()
        var center := Vector3(xs[xs.size() / 2], ys[ys.size() / 2], zs[zs.size() / 2])
        var ds: Array = []
        for p in pts:
            ds.append(p.distance_to(center))
        ds.sort()
        var radius: float = maxf(ds[int(ds.size() * 0.8)], 20.0)
        var pos := center + Vector3(0.0, radius * 0.6, radius * 1.2)
        var dir := (center - pos).normalized()
        cam.position = pos
        cam.rotation = Vector3(asin(clampf(dir.y, -1.0, 1.0)), atan2(-dir.x, -dir.z), 0.0)
        Log.info("city", "mesh=%d merkez=%s yari=%s" % [meshes, str(center), str(radius)])
    cam.current = true
