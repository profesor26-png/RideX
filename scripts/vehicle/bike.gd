extends RigidBody3D
## Arcade motosiklet: raycast zemin, dik tutma, gaz/fren/donus, motor sesi.

var throttle := 0.0
var brake := 0.0
var steer := 0.0

@export var accel := 30.0
@export var max_speed := 42.0
@export var turn_torque := 2400.0
@export var upright_torque := 9000.0
@export var downforce := 7000.0

var _ray: RayCast3D
var _grounded := false
var _engine: AudioStreamPlayer3D
var _log_t := 0.0


func _ready() -> void:
    mass = 220.0
    gravity_scale = 1.0
    angular_damp = 3.0
    linear_damp = 0.1
    continuous_cd = true
    can_sleep = false

    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.7, 1.0, 2.0)
    cs.shape = box
    add_child(cs)

    if not _attach_model("res://assets/scene/mt07.glb"):
        _build_placeholder()

    _ray = RayCast3D.new()
    _ray.target_position = Vector3(0, -1.6, 0)
    _ray.enabled = true
    add_child(_ray)

    _setup_engine_audio()


func _collect_aabb(n: Node, xf: Transform3D) -> Array:
    var first := true
    var box := AABB()
    if n is MeshInstance3D and n.mesh != null:
        box = xf * n.transform * n.mesh.get_aabb()
        first = false
    for c in n.get_children():
        var r := _collect_aabb(c, xf * n.transform)
        if not r[0]:
            if first:
                box = r[1]
                first = false
            else:
                box = box.merge(r[1])
    return [first, box]


func _attach_model(path: String) -> bool:
    var ps = load(path)
    if ps == null:
        return false
    var model = ps.instantiate()
    if model == null:
        return false
    var r := _collect_aabb(model, Transform3D.IDENTITY)
    if r[0]:
        return false
    var aabb: AABB = r[1]
    var size := aabb.size
    var longest := maxf(size.x, maxf(size.y, size.z))
    if longest < 0.01:
        return false
    var s := 1.9 / longest
    model.scale = Vector3.ONE * s
    model.rotate_y(PI)
    var c := aabb.get_center()
    model.position = Vector3(-c.x * s, -aabb.position.y * s + 0.45, -c.z * s)
    add_child(model)
    return true


func _build_placeholder() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.85, 0.15, 0.1)
    var body := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.55, 0.55, 1.8)
    body.mesh = bm
    body.material_override = mat
    add_child(body)


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
    if _log_t >= 1.0:
        _log_t = 0.0
        Log.info("bike", "spd=%.1f thr=%.1f gnd=%s" % [speed, throttle, str(_grounded)])
