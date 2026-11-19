extends Node
## RideX merkezi log sistemi (autoload adi: Log)
##
## Kullanim:
##     Log.section("DUNYA YUKLENIYOR")
##     Log.debug("sky", "hdri %s yuklendi" % name)
##     Log.info("vehicle", "motor calisti")
##     Log.warn("vehicle", "tekerlek temasi yok")
##     Log.error("save", "kayit acilamadi: %s" % path)
##
## Loglar hem konsola hem dosyaya yazilir. Dosya konumu iOS'ta
## "Dosyalar" uygulamasindan gorulebilir (UIFileSharingEnabled).

signal line_written(entry: Dictionary)

enum Level { DEBUG, INFO, WARN, ERROR }

const LEVEL_TAG := ["DEBUG", "INFO ", "WARN ", "ERROR"]
const MAX_MEMORY := 400
const MAX_FILE_BYTES := 2 * 1024 * 1024

## Bu seviyenin altindaki loglar yazilmaz. Faz 3'te INFO'ya cekelim.
var min_level: int = Level.DEBUG
## Konsola da yaz (CI/editor ciktisinda gorunur).
var echo_console := true

var log_path := ""
var session_id := ""

var _file: FileAccess = null
var _memory: Array[Dictionary] = []
var _start_ms := 0
var _lines_written := 0
var _errors := 0
var _warnings := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_ms = Time.get_ticks_msec()
	session_id = Time.get_datetime_string_from_system().replace(":", "").replace("T", "-")
	log_path = _resolve_log_path()
	_open_file()
	_write_header()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush()
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
			_flush()


func _flush() -> void:
	if _file:
		_file.flush()


# ---------------------------------------------------------------- genel API

func section(title: String) -> void:
	_log(Level.INFO, "----", "===== %s =====" % title)


func debug(tag: String, message: String) -> void:
	_log(Level.DEBUG, tag, message)


func info(tag: String, message: String) -> void:
	_log(Level.INFO, tag, message)


func warn(tag: String, message: String) -> void:
	_log(Level.WARN, tag, message)


func error(tag: String, message: String) -> void:
	_log(Level.ERROR, tag, message)


## Sessizce hata yutma: bir kosul saglanmazsa ERROR yaz ve false don.
func check(condition: bool, tag: String, message: String) -> bool:
	if not condition:
		error(tag, message)
	return condition


func summary() -> String:
	return "%d satir, %d uyari, %d hata" % [_lines_written, _warnings, _errors]


## Son n satiri tek metin olarak dondur (panodan kopyalamak icin).
func snapshot(n := 100) -> String:
	var out: Array[String] = []
	var start := maxi(0, _memory.size() - n)
	for i in range(start, _memory.size()):
		out.append(_memory[i]["line"])
	return "\n".join(out)


func recent(n := 20) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start := maxi(0, _memory.size() - n)
	for i in range(start, _memory.size()):
		out.append(_memory[i])
	return out


# ---------------------------------------------------------------- ic isler

func _log(level: int, tag: String, message: String) -> void:
	if level < min_level:
		return

	var elapsed := (Time.get_ticks_msec() - _start_ms) / 1000.0
	var line := "[%s +%6.2fs] [%s] [%s] %s" % [
		Time.get_time_string_from_system(), elapsed, LEVEL_TAG[level], tag, message
	]

	if level == Level.ERROR:
		_errors += 1
	elif level == Level.WARN:
		_warnings += 1

	if echo_console:
		match level:
			Level.ERROR:
				push_error(line)
			Level.WARN:
				push_warning(line)
			_:
				print(line)

	var entry := {
		"line": line,
		"level": level,
		"tag": tag,
		"message": message,
		"time": Time.get_time_string_from_system(),
	}
	_memory.append(entry)
	if _memory.size() > MAX_MEMORY:
		_memory.pop_front()

	if _file:
		_file.store_line(line)
		# Telefon cokebilirse son satirlar kaybolmasin diye her satirda flush.
		_file.flush()
		_lines_written += 1

	line_written.emit(entry)


func _resolve_log_path() -> String:
	var dir_path := "user://logs"
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		if docs != "":
			dir_path = docs.path_join("logs")

	var absolute := ProjectSettings.globalize_path(dir_path)
	var err := DirAccess.make_dir_recursive_absolute(absolute)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("[Log] klasor olusturulamadi: %s (hata %d)" % [absolute, err])

	return dir_path.path_join("ridex.log")


func _open_file() -> void:
	var absolute := ProjectSettings.globalize_path(log_path)

	# Onceki oturumu sakla: son cokme sebebini kaybetmeyelim.
	if FileAccess.file_exists(log_path):
		var prev := ProjectSettings.globalize_path(log_path.get_base_dir().path_join("ridex.prev.log"))
		if FileAccess.file_exists(prev):
			DirAccess.remove_absolute(prev)
		DirAccess.copy_absolute(absolute, prev)

	_file = FileAccess.open(log_path, FileAccess.WRITE)
	if _file == null:
		var code := FileAccess.get_open_error()
		push_error("[Log] dosya acilamadi: %s (hata %d)" % [absolute, code])
		echo_console = true


func _write_header() -> void:
	var v := Engine.get_version_info()
	section("OTURUM BASLADI")
	info("boot", "RideX %s" % ProjectSettings.get_setting("application/config/version", "?"))
	info("boot", "Godot %s (%s)" % [v["string"], v["build"] if v.has("build") else "?"])
	info("boot", "Platform: %s %s" % [OS.get_name(), OS.get_version()])
	info("boot", "Model: %s" % OS.get_model_name())
	info("boot", "CPU: %d cekirdek" % OS.get_processor_count())
	info("boot", "Renderer: %s" % str(RenderingServer.get_video_adapter_name()))
	info("boot", "Ekran: %s" % str(DisplayServer.window_get_size()))
	info("boot", "user:// -> %s" % ProjectSettings.globalize_path("user://"))
	info("boot", "log dosyasi -> %s" % ProjectSettings.globalize_path(log_path))
	if OS.has_feature("editor"):
		info("boot", "mod: editor")
	elif OS.has_feature("debug"):
		info("boot", "mod: debug build")
	else:
		info("boot", "mod: release build")
