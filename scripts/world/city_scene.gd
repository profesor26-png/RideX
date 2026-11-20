extends Node3D
## AssetRipper'in glTF sahnesini yukler + zemin + surulebilir motosiklet + takip kamerasi.

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
    var bottoms: Array = []
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
                bottoms.append(wb.position.y)
        for c in n.get_children():
            stack.append(c)

    var center := Vector3.ZERO
    var radius := 100.0
    if not pts.is_empty():
        var xs: Array = []
        var ys: Array = []
        var zs: Array = []
        for p in pts:
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
        xs.sort(); ys.sort(); zs.sort()
        center = Vector3(xs[xs.size() / 2], ys[ys.size() / 2], zs[zs.size() / 2])
        var ds: Array = []
        for p in pts:
            ds.append(p.distance_to(center))
        ds.sort()
        radius = maxf(ds[int(ds.size() * 0.8)], 20.0)

    if bottoms.is_empty():
        bottoms.append(0.0)
    bottoms.sort()
    var ground_y: float = bottoms[bottoms.size() / 2]

    # zemin collider (duz)
    var ground := StaticBody3D.new()
    var gcs := CollisionShape3D.new()
    var gbox := BoxShape3D.new()
    gbox.size = Vector3(6000, 2, 6000)
    gcs.shape = gbox
    ground.add_child(gcs)
    ground.position = Vector3(center.x, ground_y - 1.0, center.z)
    add_child(ground)

    # yakin binalara carpisma ekle
    var spawn_pos := Vector3(center.x, ground_y, center.z + 30.0)
    stack = [root]
    var colliders := 0
    while not stack.is_empty():
        var n2 = stack.pop_back()
        if n2 is MeshInstance3D:
            var wb2: AABB = n2.global_transform * n2.get_aabb()
            var mx2 := maxf(wb2.size.x, maxf(wb2.size.y, wb2.size.z))
            if mx2 < 800.0 and n2.global_position.distance_to(spawn_pos) < 350.0:
                n2.create_trimesh_collision()
                colliders += 1
        for c2 in n2.get_children():
            stack.append(c2)

    # motosiklet
    var bike: Node3D = load("res://scenes/vehicle/bike.tscn").instantiate()
    bike.position = Vector3(center.x, ground_y + 2.5, center.z + 30.0)
    add_child(bike)

    # takip kamerasi
    var cam := Camera3D.new()
    cam.fov = 75.0
    cam.near = 0.1
    cam.far = 20000.0
    cam.set_script(load("res://scripts/vehicle/chase_camera.gd"))
    add_child(cam)
    cam.target = bike
    var back: Vector3 = bike.global_transform.basis.z.normalized() * 7.0
    cam.global_position = bike.global_position + back + Vector3.UP * 3.0
    cam.current = true

    # dokunmatik kontroller
    var ui = load("res://scripts/ui/ride_controls.gd").new()
    add_child(ui)
    ui.set_bike(bike)

    Log.info("city", "mesh=%d merkez=%s yari=%s zemin=%s collider=%d" % [meshes, str(center), str(radius), str(ground_y), colliders])
