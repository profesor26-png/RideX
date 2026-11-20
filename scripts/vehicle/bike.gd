extends RigidBody3D
## Arcade motosiklet: raycast zemin, dik tutma, gaz/fren/donus, motor sesi.

var throttle := 0.0
var brake := 0.0
var steer := 0.0

@export var accel := 40.0
@export var max_speed := 42.0
@export var turn_torque := 3000.0
@export var upright_torque := 9000.0
@export var downforce := 0.0

var _ray: RayCast3D
var _grounded := false
var _engine: AudioStreamPlayer3D
var _log_t := 0.0
var _autotest := false


func _ready() -> void:
    mass = 220.0
    gravity_scale = 1.0
    angular_damp = 3.0
    linear_damp = 0.0
    continuous_cd = true
    can_sleep = false
    _autotest = OS.has_environment("AUTOTEST")

    var pm := PhysicsMaterial.new()
    pm.friction = 0.15
    physics_material_override = pm

    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.7, 1.0, 2.0)
    cs.shape = box
    add_child(cs)

    _build_bike_visual()

    _ray = RayCast3D.new()
    _ray.target_position = Vector3(0, -1.6, 0)
    _ray.enabled = true
    add_child(_ray)

    _setup_engine_audio()


func _build_bike_visual() -> void:
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color(0.85, 0.12, 0.08)
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.06, 0.06, 0.07)

    var body := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.45, 0.5, 1.5)
    body.mesh = bm
    body.material_override = paint
    body.position = Vector3(0, 0.05, 0)
    add_child(body)

    var tank := MeshInstance3D.new()
    var tm := BoxMesh.new()
    tm.size = Vector3(0.38, 0.3, 0.6)
    tank.mesh = tm
    tank.material_override = paint
    tank.position = Vector3(0, 0.42, -0.1)
    add_child(tank)

    for z in [-0.72, 0.72]:
        var w := MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = 0.33
        cyl.bottom_radius = 0.33
        cyl.height = 0.16
        cyl.radial_segments = 18
        w.mesh = cyl
        w.rotation_degrees = Vector3(0, 0, 90)
        w.position = Vector3(0, -0.38, z)
        w.material_override = dark
        add_child(w)

    var bar := MeshInstance3D.new()
    var bar_m := BoxMesh.new()
    bar_m.size = Vector3(0.7, 0.06, 0.06)
    bar.mesh = bar_m
    bar.material_override = dark
    bar.position = Vector3(0, 0.55, -0.55)
    add_child(bar)


func _setup_engine_audio() -> void:
    var st = load("res://assets/scene/audio/Engine_Generic_Idle.ogg")
    if st == null:
        return
    if st is AudioStreamOggVorbis:
        st.loop = true
    _engine = AudioStreamPlayer3D.new()
    _engine.stream = st
    _engine.unit_size = 12.0
    _engine.volume_db = -6.0
    _engine.autoplay = true
    add_child(_engine)
    _engine.play()


func _physics_process(delta: float) -> void:
    if _autotest:
        throttle = 1.0
    _grounded = _ray.is_colliding()
    var up := global_transform.basis.y
    var upright_err := clampf(1.0 - up.dot(Vector3.UP), 0.0, 1.0)
    apply_torque(up.cross(Vector3.UP) * upright_torque * upright_err)

    if throttle > 0.01 or brake > 0.01:
        sleeping = false

    var fwd := -global_transform.basis.z
    var speed := linear_velocity.dot(fwd)

    if _grounded:
        apply_central_force(-Vector3.UP * downforce)
        if throttle > 0.01 and speed < max_speed:
            apply_central_force(fwd * accel * throttle * mass)
        if brake > 0.01 and linear_velocity.length() > 0.1:
            apply_central_force(-linear_velocity.normalized() * brake * 30.0 * mass)
        var steer_scale := clampf(absf(speed) / 12.0, 0.0, 1.0)
        apply_torque(Vector3.UP * -steer * turn_torque * steer_scale)
        apply_torque(fwd.cross(Vector3.UP) * steer * 1200.0 * steer_scale)

    if _engine != null:
        var t := clampf(absf(speed) / max_speed, 0.0, 1.0)
        _engine.pitch_scale = 0.8 + throttle * 0.7 + t * 1.0
        _engine.volume_db = -8.0 + throttle * 6.0

    _log_t += delta
    if _log_t >= 1.0 and _autotest:
        _log_t = 0.0
        Log.info("bike", "spd=%.2f thr=%.1f gnd=%s pos=%.1f,%.1f" % [speed, throttle, str(_grounded), global_position.x, global_position.z])
