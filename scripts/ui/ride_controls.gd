extends CanvasLayer
## Dokunmatik surus: gaz/fren/sol/sag.

var bike: Node = null


func set_bike(b: Node) -> void:
    bike = b


func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _btn(root, "GAZ", 0.82, 0.62, func(): _set_prop("throttle", 1.0), func(): _set_prop("throttle", 0.0))
    _btn(root, "FREN", 0.82, 0.80, func(): _set_prop("brake", 1.0), func(): _set_prop("brake", 0.0))
    _btn(root, "<", 0.06, 0.74, func(): _set_prop("steer", -1.0), func(): _set_prop("steer", 0.0))
    _btn(root, ">", 0.20, 0.74, func(): _set_prop("steer", 1.0), func(): _set_prop("steer", 0.0))


func _set_prop(prop: String, v: float) -> void:
    if bike != null:
        bike.set(prop, v)


func _btn(parent: Control, txt: String, ax: float, ay: float, on: Callable, off: Callable) -> void:
    var b := Button.new()
    b.text = txt
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.anchor_left = ax
    b.anchor_top = ay
    b.offset_right = 86
    b.offset_bottom = 86
    b.add_theme_font_size_override("font_size", 22)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.0, 0.0, 0.0, 0.4)
    sb.set_corner_radius_all(12)
    b.add_theme_stylebox_override("normal", sb)
    var sbp := StyleBoxFlat.new()
    sbp.bg_color = Color(0.2, 0.7, 1.0, 0.6)
    sbp.set_corner_radius_all(12)
    b.add_theme_stylebox_override("pressed", sbp)
    b.button_down.connect(on)
    b.button_up.connect(off)
    parent.add_child(b)
