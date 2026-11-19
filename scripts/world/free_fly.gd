extends Camera3D
## Butonlu serbest ucus: ekran butonlari hareket, sag yari surukleme bakis.
## PC: WASD + Shift, sag tik bakis, Space/Ctrl yukari/asagi.

@export var speed := 150.0
@export var boost := 3.0
@export var look_sens := 0.004

var _yaw := 0.0
var _pitch := 0.0
var _inited := false
var _touch_look := -1

var _fwd := false
var _back := false
var _left := false
var _right := false
var _up := false
var _down := false


func _ready() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    _btn(root, "▲", 0.06, 0.58, func(): _fwd = true, func(): _fwd = false)
    _btn(root, "▼", 0.06, 0.78, func(): _back = true, func(): _back = false)
    _btn(root, "◀", 0.005, 0.68, func(): _left = true, func(): _left = false)
    _btn(root, "▶", 0.115, 0.68, func(): _right = true, func(): _right = false)
    _btn(root, "⤒", 0.23, 0.58, func(): _up = true, func(): _up = false)
    _btn(root, "⤓", 0.23, 0.78, func(): _down = true, func(): _down = false)


func _btn(parent: Control, txt: String, ax: float, ay: float, on: Callable, off: Callable) -> void:
    var b := Button.new()
    b.text = txt
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.anchor_left = ax
    b.anchor_top = ay
    b.offset_left = 0
    b.offset_top = 0
    b.offset_right = 68
    b.offset_bottom = 68
    b.add_theme_font_size_override("font_size", 26)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.0, 0.0, 0.0, 0.35)
    sb.set_corner_radius_all(10)
    b.add_theme_stylebox_override("normal", sb)
    var sbp := StyleBoxFlat.new()
    sbp.bg_color = Color(0.2, 0.6, 1.0, 0.55)
    sbp.set_corner_radius_all(10)
    b.add_theme_stylebox_override("pressed", sbp)
    b.button_down.connect(on)
    b.button_up.connect(off)
    parent.add_child(b)


func _process(delta: float) -> void:
    if not _inited:
        _yaw = rotation.y
        _pitch = rotation.x
        _inited = true

    var dir := Vector3.ZERO
    if _fwd or Input.is_key_pressed(KEY_W):
        dir -= basis.z
    if _back or Input.is_key_pressed(KEY_S):
        dir += basis.z
    if _left or Input.is_key_pressed(KEY_A):
        dir -= basis.x
    if _right or Input.is_key_pressed(KEY_D):
        dir += basis.x
    if _up or Input.is_key_pressed(KEY_SPACE):
        dir += Vector3.UP
    if _down or Input.is_key_pressed(KEY_CTRL):
        dir -= Vector3.UP

    var sp := speed
    if Input.is_key_pressed(KEY_SHIFT):
        sp *= boost
    if dir.length() > 0.01:
        position += dir.normalized() * sp * delta

    rotation = Vector3(_pitch, _yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_look = event.index
        elif event.index == _touch_look:
            _touch_look = -1
    elif event is InputEventScreenDrag and event.index == _touch_look:
        _yaw -= event.relative.x * look_sens
        _pitch -= event.relative.y * look_sens
        _pitch = clampf(_pitch, -1.5, 1.5)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _yaw -= event.relative.x * look_sens
        _pitch -= event.relative.y * look_sens
        _pitch = clampf(_pitch, -1.5, 1.5)
