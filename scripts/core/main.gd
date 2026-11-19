extends Node3D
## Faz 1 test sahnesi.
## Amac: kod -> IPA -> telefon zincirinin calistigini kanitlamak.
## Oyun yok; sadece render, isik, yazi ve dokunma testi var.

var _box: MeshInstance3D
var _spin := 0.0


func _ready() -> void:
	Log.section("ANA SAHNE YUKLENIYOR")
	_build_environment()
	_build_light()
	_build_ground()
	_build_test_box()
	_build_labels()
	_build_camera()

	Log.info("world", "sahne hazir")
	Log.info("world", "gorunur alan: %s" % str(get_viewport().get_visible_rect().size))
	Log.info("world", "ilk kare FPS: %d" % Engine.get_frames_per_second())
	Log.info("world", "ekrana dokun: log panelinde 'input' satiri gorunmeli")


func _process(delta: float) -> void:
	if _box:
		_spin += delta * 0.7
		_box.rotation.y = _spin


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		Log.info("input", "dokunma: index=%d pos=%s" % [event.index, str(event.position)])
	elif event is InputEventMouseButton and event.pressed:
		Log.info("input", "tik: btn=%d pos=%s" % [event.button_index, str(event.position)])


# ---------------------------------------------------------------- sahne

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.29, 0.49)
	sky_mat.sky_horizon_color = Color(0.62, 0.71, 0.79)
	sky_mat.ground_bottom_color = Color(0.10, 0.10, 0.12)
	sky_mat.ground_horizon_color = Color(0.35, 0.36, 0.40)

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = false

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)
	Log.debug("world", "gokyuzu + ortam hazir")


func _build_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	Log.debug("world", "gunes + golge hazir")


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.21, 0.23)
	mat.roughness = 0.92

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)
	Log.debug("world", "zemin hazir")


func _build_test_box() -> void:
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.6, 1.6, 1.6)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.35, 0.12)
	mat.roughness = 0.35
	mat.metallic = 0.15

	_box = MeshInstance3D.new()
	_box.name = "TestBox"
	_box.mesh = box_mesh
	_box.material_override = mat
	_box.position = Vector3(0, 1.0, 0)
	add_child(_box)
	Log.debug("world", "donen test kupu hazir")


func _build_labels() -> void:
	var title := Label3D.new()
	title.text = "RideX"
	title.font_size = 128
	title.pixel_size = 0.008
	title.position = Vector3(0, 3.6, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1)
	title.outline_size = 14
	add_child(title)

	var sub := Label3D.new()
	sub.text = "Faz 1 - pipeline testi"
	sub.font_size = 40
	sub.pixel_size = 0.006
	sub.position = Vector3(0, 2.7, 0)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub.modulate = Color(0.85, 0.88, 0.92)
	sub.outline_size = 8
	add_child(sub)
	Log.debug("world", "basliklar hazir")


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.position = Vector3(0, 4.5, 9.0)
	cam.fov = 65.0
	add_child(cam)
	cam.look_at(Vector3(0, 1.2, 0))
	cam.current = true
	Log.debug("world", "kamera hazir")
