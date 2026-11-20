extends RigidBody3D
## Arcade motosiklet: raycast zemin, dik tutma, gaz/fren/donus.

var throttle := 0.0
var brake := 0.0
var steer := 0.0

@export var accel := 26.0
@export var max_speed := 38.0
@export var turn_torque := 2400.0
@export var upright_torque := 9000.0
@export var downforce := 7000.0

var _ray: RayCast3D
var _grounded := false


func _ready() -> void:
    mass = 220.0
    gravity_scale = 1.0
    angular_damp = 3.0
    linear_damp = 0.2
    continuous_cd = true

    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.6, 0.9, 1.9)
    cs.shape = box
    add_child(cs)

    _build_visual()

    _ray = RayCast3D.new()
    _ray.target_position = Vector3(0, -1.5, 0)
    _ray.enabled = true
    add_child(_ray)


func _build_visual() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.85, 0.15, 0.1)

    var body := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.55, 0.55, 1.8)
    body.mesh = bm
    body.material_override = mat
    add_child(body)

    var wmat := StandardMaterial3D.new()
    wmat.albedo_color = Color(0.05, 0.05, 0.05)
    for z in [-0.7, 0.7]:
        var w := MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = 0.34
        cyl.bottom_radius = 0.34
        cyl.height = 0.18
        cyl.radial_segments = 16
        w.mesh = cyl
        w.rotation_degrees = Vector3(0, 0, 90)
        w.position = Vector3(0, -0.4, z)
        w.material_override = wmat
        add_child(w)


func _physics_process(_delta: float) -> void:
    _grounded = _ray.is_colliding()
    var up := global_transform.basis.y
    var upright_err := clampf(1.0 - up.dot(Vector3.UP), 0.0, 1.0)
    apply_torque(up.cross(Vector3.UP) * upright_torque * upright_err)

    if _grounded:
        apply_central_force(-Vector3.UP * downforce)
        var fwd := -global_transform.basis.z
        var speed := linear_velocity.dot(fwd)
        if throttle > 0.01 and speed < max_speed:
            apply_central_force(fwd * accel * throttle * mass)
        if brake > 0.01 and linear_velocity.length() > 0.1:
            apply_central_force(-linear_velocity.normalized() * brake * 30.0 * mass)
        var steer_scale := clampf(absf(speed) / 12.0, 0.0, 1.0)
        apply_torque(Vector3.UP * -steer * turn_torque * steer_scale)
        apply_torque(fwd.cross(Vector3.UP) * steer * 1200.0 * steer_scale)
