extends Node3D
## Haritayi kurar; yukleme barli (yuzde) async build.

@export var base_path: String = "res://assets/projeto/"
@export var max_objects: int = 0
@export var collision: bool = false
@export var static_only: bool = false

var _load_layer: CanvasLayer
var _load_bar: ProgressBar
var _load_label: Label


func _ready() -> void:
    _build_environment()

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -35, 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = false
    add_child(sun)

    _build_loading()

    var imp := MapImporter.new()
    imp.base_path = base_path
    imp.max_objects = max_objects
    imp.verbose = true
    imp.collision = collision
    imp.static_only = static_only
    imp.world_scale = 1.0
    imp.unshaded = false
    add_child(imp)

    var st = await imp.build_async(_on_progress)
    Log.info("map", "harita: %s" % str(st))
    _finish_loading()

    var cam := Camera3D.new()
    cam.fov = 70.0
    cam.near = 0.1
    cam.far = 30000.0
    cam.set_script(load("res://scripts/world/free_fly.gd"))
    add_child(cam)

    # aykiri obje temizligi (sehir merkezinden uzak / ucan)
    var city_pts2: Array = []
    for c in imp.get_children():
        if c is MeshInstance3D and c.get_meta("city", false):
            city_pts2.append(c.transform.origin)
    var city_center := Vector3.ZERO
    if not city_pts2.is_empty():
        var ax: Array = []
        var ay: Array = []
        var az: Array = []
        for p in city_pts2:
            ax.append(p.x); ay.append(p.y); az.append(p.z)
        ax.sort(); ay.sort(); az.sort()
        city_center = Vector3(ax[ax.size() / 2], ay[ay.size() / 2], az[az.size() / 2])
    var removed := 0
    for c in imp.get_children():
        if c is MeshInstance3D and not c.get_meta("city", false):
            var p: Vector3 = c.transform.origin
            if p.distance_to(city_center) > 2800.0 or p.y < -80.0 or p.y > 250.0:
                c.free()
                removed += 1
    Log.info("map", "aykiri temizlenen: %d" % removed)

    var pts: Array = []
    for c in imp.get_children():
        if c is MeshInstance3D and c.get_meta("city", false):
            pts.append(c.transform.origin)
    if pts.is_empty():
        for c in imp.get_children():
            if c is MeshInstance3D:
                pts.append(c.transform.origin)

    if pts.is_empty():
        cam.position = Vector3(0, 200, 400)
        cam.rotation = Vector3(-0.4, 0, 0)
        Log.info("map", "obje yok, varsayilan kamera")
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
        var radius: float = maxf(ds[int(ds.size() * 0.8)], 10.0)
        var pos := center + Vector3(0.0, radius * 0.6, radius * 1.2)
        var dir := (center - pos).normalized()
        cam.position = pos
        cam.rotation = Vector3(asin(clampf(dir.y, -1.0, 1.0)), atan2(-dir.x, -dir.z), 0.0)
        Log.info("map", "kamera merkez=%s yari=%s obje=%d" % [str(center), str(radius), pts.size()])
    cam.current = true


func _build_environment() -> void:
    var world_env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    world_env.environment = e
    add_child(world_env)


func _build_loading() -> void:
    _load_layer = CanvasLayer.new()
    add_child(_load_layer)

    var bg := ColorRect.new()
    bg.color = Color(0.03, 0.04, 0.06, 1.0)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _load_layer.add_child(bg)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _load_layer.add_child(center)

    var vb := VBoxContainer.new()
    vb.custom_minimum_size = Vector2(460, 0)
    center.add_child(vb)

    _load_label = Label.new()
    _load_label.text = "Harita yukleniyor... %0"
    _load_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _load_label.add_theme_font_size_override("font_size", 26)
    vb.add_child(_load_label)

    _load_bar = ProgressBar.new()
    _load_bar.min_value = 0.0
    _load_bar.max_value = 100.0
    _load_bar.value = 0.0
    _load_bar.custom_minimum_size = Vector2(460, 30)
    _load_bar.show_percentage = false
    vb.add_child(_load_bar)


func _on_progress(p: float, done: int, total: int) -> void:
    if _load_bar:
        _load_bar.value = p * 100.0
    if _load_label:
        _load_label.text = "Harita yukleniyor... %%%d  (%d/%d)" % [int(p * 100.0), done, total]


func _finish_loading() -> void:
    if _load_layer:
        _load_layer.visible = false
        _load_layer.queue_free()
        _load_layer = null
