extends Camera3D
## Serbest ucus: PC WASD + sag-tik bakis, mobil sol-yari hareket + sag-yari bakis.

@export var speed := 90.0
@export var boost := 3.0
@export var look_sens := 0.004

var _yaw := 0.0
var _pitch := 0.0
var _inited := false
var _move_origin := Vector2.ZERO
var _move := Vector2.ZERO
var _touch_move := -1
var _touch_look := -1


func _process(delta: float) -> void:
    if not _inited:
        _yaw = rotation.y
        _pitch = rotation.x
        _inited = true

    var dir := Vector3.ZERO
    if Input.is_key_pressed(KEY_W):
        dir -= basis.z
    if Input.is_key_pressed(KEY_S):
        dir += basis.z
    if Input.is_key_pressed(KEY_A):
        dir -= basis.x
    if Input.is_key_pressed(KEY_D):
        dir += basis.x
    if Input.is_key_pressed(KEY_SPACE):
        dir += Vector3.UP
    if Input.is_key_pressed(KEY_CTRL):
        dir -= Vector3.UP

    dir += -basis.z * (-_move.y) + basis.x * _move.x

    var sp := speed
    if Input.is_key_pressed(KEY_SHIFT):
        sp *= boost
    if dir.length() > 0.01:
        position += dir.normalized() * sp * delta * (1.0 + _move.length())

    rotation = Vector3(_pitch, _yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
    var vp := get_viewport().get_visible_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < vp.x * 0.4:
                _touch_move = event.index
                _move_origin = event.position
            else:
                _touch_look = event.index
        else:
            if event.index == _touch_move:
                _touch_move = -1
                _move = Vector2.ZERO
            if event.index == _touch_look:
                _touch_look = -1
    elif event is InputEventScreenDrag:
        if event.index == _touch_move and _touch_move != -1:
            var d: Vector2 = (event.position - _move_origin) / 120.0
            _move = Vector2(clampf(d.x, -1.0, 1.0), clampf(d.y, -1.0, 1.0))
        elif event.index == _touch_look and _touch_look != -1:
            _yaw -= event.relative.x * look_sens
            _pitch -= event.relative.y * look_sens
            _pitch = clampf(_pitch, -1.5, 1.5)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _yaw -= event.relative.x * look_sens
        _pitch -= event.relative.y * look_sens
        _pitch = clampf(_pitch, -1.5, 1.5)
