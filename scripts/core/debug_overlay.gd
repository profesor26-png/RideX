extends CanvasLayer
## Telefonda ekrandan acilan log paneli (autoload adi: DebugOverlay).
##
## Mac/Xcode olmadan cihazda ne oldugunu gormek icin.
## Sol ustteki "LOG" dugmesine dokun (bilgisayarda F3).
## Panelde FPS, cizim sayisi, RAM ve son log satirlari gorunur.
## "KOPYALA" butonu loglari panoya alir.

const MAX_LINES := 24
const REFRESH_SEC := 0.25

var _root: Control
var _panel: PanelContainer
var _stats: Label
var _text: RichTextLabel
var _toggle: Button
var _lines: Array[String] = []
var _open := false
var _elapsed := 0.0


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	Log.line_written.connect(_on_log_line)
	for entry in Log.recent(MAX_LINES):
		_on_log_line(entry)
	Log.info("ui", "debug paneli hazir (LOG dugmesi / F3)")


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SEC:
		return
	_elapsed = 0.0
	if _open:
		_update_stats()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_toggle_panel()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- arayuz

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "OverlayRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_toggle = Button.new()
	_toggle.text = "LOG"
	_toggle.focus_mode = Control.FOCUS_NONE
	_toggle.modulate = Color(1, 1, 1, 0.45)
	_toggle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_toggle.offset_left = 8
	_toggle.offset_top = 8
	_toggle.offset_right = 66
	_toggle.offset_bottom = 44
	_toggle.pressed.connect(_toggle_panel)
	_root.add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 8
	_panel.offset_top = 50
	_panel.offset_right = 8 + 640
	_panel.offset_bottom = 50 + 330
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.05, 0.90)
	style.border_color = Color(0.35, 0.45, 0.55, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	var bar := HBoxContainer.new()
	vbox.add_child(bar)

	_stats = Label.new()
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats.add_theme_font_size_override("font_size", 13)
	bar.add_child(_stats)

	var copy_btn := Button.new()
	copy_btn.text = "KOPYALA"
	copy_btn.focus_mode = Control.FOCUS_NONE
	copy_btn.pressed.connect(_copy_logs)
	bar.add_child(copy_btn)

	var clear_btn := Button.new()
	clear_btn.text = "TEMIZLE"
	clear_btn.focus_mode = Control.FOCUS_NONE
	clear_btn.pressed.connect(_clear_logs)
	bar.add_child(clear_btn)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(_text)


func _toggle_panel() -> void:
	_open = not _open
	_panel.visible = _open
	_toggle.modulate = Color(1, 1, 1, 0.95 if _open else 0.45)
	if _open:
		_update_stats()
		_text.text = "\n".join(_lines)
		Log.debug("ui", "panel acildi")


func _update_stats() -> void:
	var fps := Engine.get_frames_per_second()
	var draws := int(RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var ram_mb := OS.get_static_memory_usage() / (1024.0 * 1024.0)
	_stats.text = "FPS %d | cizim %d | ucgen %d | RAM %.0fMB | %s" % [
		fps, draws, prims, ram_mb, Log.summary()
	]


# ---------------------------------------------------------------- log

func _on_log_line(entry: Dictionary) -> void:
	var color := ["#8b949e", "#c9d1d9", "#d29922", "#f85149"][int(entry["level"])]
	_lines.append("[color=%s]%s[/color]" % [color, str(entry["line"])])
	if _lines.size() > MAX_LINES:
		_lines.pop_front()
	if _open:
		_text.text = "\n".join(_lines)


func _copy_logs() -> void:
	DisplayServer.clipboard_set(Log.snapshot(120))
	Log.info("ui", "loglar panoya kopyalandi")


func _clear_logs() -> void:
	_lines.clear()
	if _text:
		_text.text = ""
