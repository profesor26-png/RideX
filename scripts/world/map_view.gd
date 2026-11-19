extends Node3D
## Haritayi Unity asset'lerinden kurup kamerayi sehre sigdiran sahne.

@export var base_path: String = "res://assets/projeto/"
@export var max_objects: int = 0
@export var collision: bool = false
@export var static_only: bool = false


func _ready() -> void:
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

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -35, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = false
    add_child(sun)

    var imp := MapImporter.new()
    imp.base_path = base_path
    imp.max_objects = max_objects
    imp.verbose = true
    imp.collision = collision
    imp.static_only = static_only
    add_child(imp)
    var st := imp.build()
    Log.info("map", "harita: %s" % str(st))

    var cam := Camera3D.new()
    cam.fov = 70.0
    cam.near = 0.1
    cam.far = 30000.0
    cam.set_script(load("res://scripts/world/free_fly.gd"))
    add_child(cam)

    var aabb := AABB()
    var first := true
    for c in imp.get_children():
        if c is MeshInstance3D:
            var lb: AABB = c.get_aabb()
            if maxf(lb.size.x, maxf(lb.size.y, lb.size.z)) < 300.0:
                continue
            var wb: AABB = c.transform * lb
            if first:
                aabb = wb
                first = false
            else:
                aabb = aabb.merge(wb)

    if first:
        cam.position = Vector3(0, 200, 400)
        cam.rotation = Vector3(-0.4, 0, 0)
        Log.info("map", "buyuk mesh yok, varsayilan kamera")
    else:
        var center := aabb.get_center()
        var radius := aabb.size.length()
        var pos := center + Vector3(0.0, radius * 0.02, radius * 0.04)
        var dir := (center - pos).normalized()
        var yaw := atan2(-dir.x, -dir.z)
        var pitch := asin(clampf(dir.y, -1.0, 1.0))
        cam.position = pos
        cam.rotation = Vector3(pitch, yaw, 0.0)
        Log.info("map", "kamera merkez=%s cap=%s" % [str(center), str(aabb.size)])
    cam.current = true
