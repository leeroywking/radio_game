extends Node2D

const WORLD_SIZE := Vector2(1280, 720)
const PLAY_AREA := Rect2(Vector2(400, 40), Vector2(840, 640))
const PLAYER_RADIUS := 10.0
const PLAYER_START := Vector2(520, 560)
const BEARING_LENGTH := 2000.0
const MAX_DISTANCE := 900.0
const OVERLOAD_DISTANCE := 70.0
const SCOPE_RECT := Rect2(Vector2(32, 204), Vector2(322, 72))
const WATERFALL_RECT := Rect2(Vector2(32, 324), Vector2(322, 92))
const MAP_BOARD_RECT := Rect2(Vector2(392, 92), Vector2(840, 556))
const MAP_BOARD_RING_CENTER := Vector2(194, 218)
const MAP_BOARD_RING_RADIUS := 92.0
const COMPASS_CENTER := Vector2(1160, 618)
const COMPASS_RADIUS := 66.0
const MAP_PATH := "res://assets/maps/wa_hillshade.png"
const STATIC_WAV_PATH := "res://assets/audio/static_noise.wav"
const SCANNER_MIN_FREQ := 144.000
const SCANNER_MAX_FREQ := 148.000
const SCANNER_STEP := 0.005
const TUNE_WINDOW := 0.012
const TARGET_BROADCAST_ID := "real_conversation"
const WATERFALL_BINS := 72
const WATERFALL_HISTORY := 36
const TERRAIN_SIZE := Vector2(2048.0, 2048.0)
const TERRAIN_HEIGHT_SCALE := 340.0
const TERRAIN_HEIGHT_OFFSET := -120.0
const PLAYER_MOVE_SPEED := 125.0
const PLAYER_EYE_HEIGHT := 1.7
const PLAYER_LOOK_SENSITIVITY := 0.0022
const TREE_COUNT := 260
const TREE_LINE_ALTITUDE := 180.0
const BROADCAST_BOUNDS := Rect2(Vector2(470, 90), Vector2(680, 520))
const BROADCAST_TEMPLATES := [
	{
		"id": "lesson_alpha",
		"label": "Educational Alpha",
		"path": "res://assets/audio/training_alpha.wav",
		"gain_db": 0.0,
		"role": "education",
		"frequency": 144.925,
		"position": Vector2(640, 150)
	},
	{
		"id": "lesson_bravo",
		"label": "Educational Bravo",
		"path": "res://assets/audio/training_bravo.wav",
		"gain_db": 0.0,
		"role": "education",
		"frequency": 145.410,
		"position": Vector2(1140, 560)
	},
	{
		"id": "lesson_charlie",
		"label": "Educational Charlie",
		"path": "res://assets/audio/training_charlie.wav",
		"gain_db": 0.0,
		"role": "education",
		"frequency": 147.155,
		"position": Vector2(760, 600)
	},
	{
		"id": "lesson_delta",
		"label": "Educational Delta",
		"path": "res://assets/audio/training_voice_human_voice.mp3",
		"gain_db": -1.5,
		"role": "education",
		"frequency": 144.540,
		"position": Vector2(980, 140)
	},
	{
		"id": "lesson_echo",
		"label": "Educational Echo",
		"path": "res://assets/audio/training_voice_umbriel.mp3",
		"gain_db": -1.0,
		"role": "education",
		"frequency": 146.780,
		"position": Vector2(1180, 300)
	},
	{
		"id": "real_conversation",
		"label": "Real Conversation",
		"path": "res://assets/audio/ham_contest_exchange.wav",
		"gain_db": 6.0,
		"role": "target",
		"frequency": 146.235,
		"position": Vector2(1030, 210)
	}
]

var player_position := PLAYER_START
var fix_position: Vector2 = Vector2.ZERO
var fix_placed := false
var result_text := ""
var show_target := false
var bearings: Array = []
var broadcasts: Array = []
var scope_samples: Array = []
var waterfall_rows: Array = []
var map_texture: Texture2D = null
var map_image: Image = null
var waterfall_texture: ImageTexture = null

var df_voice_player: AudioStreamPlayer = null
var df_noise_player: AudioStreamPlayer = null
var scanner_voice_player: AudioStreamPlayer = null
var audio_stream_cache := {}
var current_df_broadcast_id := ""
var current_scanner_broadcast_id := ""
var clean_monitor_enabled := false
var map_board_visible := false
var df_frequency := 145.000
var df_volume := 0.85
var scanner_volume := 0.70
var smoothed_voice_level := 0.0
var smoothed_noise_level := 1.0
var bearing_capture_audio_hold_timer := 0.0
var bearing_capture_audio_hold_broadcast_id := ""

var scanner_active := false
var scanner_locked := false
var scanner_locked_broadcast_id := ""
var scanner_frequency := SCANNER_MIN_FREQ
var scanner_hop_timer := 0.0
var scanner_step_index := 0
var scanner_lock_strength := 0.0

var receiver_profile := {
	"voice_level": 0.0,
	"noise_level": 1.0,
	"quality": "searching",
	"state": "idle",
	"clarity_base": 0.0,
	"broadcast_id": ""
}

var scanner_profile := {
	"voice_level": 0.0,
	"state": "idle",
	"frequency": SCANNER_MIN_FREQ,
	"broadcast_id": ""
}

var terrain_ready := false
var terrain_height_min := 0.0
var terrain_height_max := 0.0
var tree_count_actual := 0
var mouse_capture_active := false
var player_yaw := 0.0
var player_pitch := -0.08

var world_container: SubViewportContainer = null
var world_viewport: SubViewport = null
var world_root: Node3D = null
var terrain = null
var terrain_material = null
var terrain_assets = null
var player_body: CharacterBody3D = null
var player_camera_yaw: Node3D = null
var player_camera_pitch: Node3D = null
var player_camera: Camera3D = null
var tree_trunks: MultiMeshInstance3D = null
var tree_crowns: MultiMeshInstance3D = null

var testing_aim_override_enabled := false
var testing_aim_direction := Vector2.RIGHT

@onready var root_control: Control = $HUD/Root
@onready var panel: Panel = $HUD/Root/Panel
@onready var status_label: Label = $HUD/Root/Panel/Status
@onready var welcome_modal: ColorRect = $HUD/Root/WelcomeModal
@onready var welcome_button: Button = $HUD/Root/WelcomeModal/WelcomePanel/WelcomeButton
@onready var welcome_body: Label = $HUD/Root/WelcomeModal/WelcomePanel/WelcomeBody
@onready var instructions_label: Label = $HUD/Root/Panel/Instructions
@onready var submit_button: Button = $HUD/Root/Panel/SubmitButton
@onready var reset_button: Button = $HUD/Root/Panel/ResetButton
@onready var clean_monitor_checkbox: CheckBox = $HUD/Root/Panel/CleanMonitor
@onready var scanner_button: Button = $HUD/Root/Panel/ScannerButton
@onready var scanner_unlock_button: Button = $HUD/Root/Panel/ScannerUnlockButton
@onready var map_board_button: Button = $HUD/Root/Panel/MapBoardButton
@onready var df_frequency_slider: HSlider = $HUD/Root/Panel/DFFrequencySlider
@onready var df_frequency_value: Label = $HUD/Root/Panel/DFFrequencyValue
@onready var df_frequency_input: LineEdit = $HUD/Root/Panel/DFFrequencyInput
@onready var df_volume_slider: HSlider = $HUD/Root/Panel/DFVolumeSlider
@onready var scanner_volume_slider: HSlider = $HUD/Root/Panel/ScannerVolumeSlider
@onready var df_volume_value: Label = $HUD/Root/Panel/DFVolumeValue
@onready var scanner_volume_value: Label = $HUD/Root/Panel/ScannerVolumeValue
@onready var waterfall_display: TextureRect = $HUD/Root/Panel/WaterfallDisplay
@onready var map_board_overlay: Control = $HUD/Root/MapBoardOverlay
@onready var map_board_status_label: Label = $HUD/Root/MapBoardOverlay/MapBoardStatus
@onready var map_board_bearing_list: Label = $HUD/Root/MapBoardOverlay/MapBoardBearingList


func _ready() -> void:
	randomize()
	_setup_world_view()
	_load_map_texture()
	_setup_terrain_world()
	_setup_audio()
	_reset_broadcasts()
	_setup_ui()
	_reset_hunt()
	queue_redraw()


func _setup_ui() -> void:
	welcome_body.text = "Purpose: learn to identify the real conversation, take clean bearings, and plot a usable fix.\n\nThis migration slice now uses a full first-person terrain view.\n\nCore controls:\n- Click in the field view to capture the mouse\n- WASD move across terrain\n- Mouse looks the can-antenna heading\n- Type a frequency, drag the DF slider, or click the waterfall to tune\n- Space captures a bearing\n- M opens the map board\n- Esc releases the mouse"
	welcome_button.pressed.connect(_dismiss_welcome_modal)
	submit_button.pressed.connect(_submit_fix)
	reset_button.pressed.connect(_reset_hunt)
	scanner_button.pressed.connect(_trigger_scanner)
	scanner_unlock_button.pressed.connect(_unlock_scanner)
	map_board_button.pressed.connect(_toggle_map_board)
	clean_monitor_checkbox.toggled.connect(_on_clean_monitor_toggled)
	df_frequency_slider.value_changed.connect(_on_df_frequency_changed)
	df_frequency_input.text_submitted.connect(_on_df_frequency_text_entered)
	df_frequency_input.focus_exited.connect(_on_df_frequency_focus_exited)
	df_volume_slider.value_changed.connect(_on_df_volume_changed)
	scanner_volume_slider.value_changed.connect(_on_scanner_volume_changed)
	clean_monitor_checkbox.button_pressed = clean_monitor_enabled
	df_frequency_slider.value = df_frequency
	df_volume_slider.value = df_volume * 100.0
	scanner_volume_slider.value = scanner_volume * 100.0
	_sync_control_labels()
	_sync_overlay_visibility()


func _setup_world_view() -> void:
	world_container = SubViewportContainer.new()
	world_container.anchor_right = 0.0
	world_container.anchor_bottom = 0.0
	world_container.offset_left = PLAY_AREA.position.x
	world_container.offset_top = PLAY_AREA.position.y
	world_container.offset_right = PLAY_AREA.end.x
	world_container.offset_bottom = PLAY_AREA.end.y
	world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(world_container)
	root_control.move_child(world_container, 0)

	world_viewport = SubViewport.new()
	world_viewport.disable_3d = false
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.size = Vector2i(int(PLAY_AREA.size.x), int(PLAY_AREA.size.y))
	world_container.add_child(world_viewport)

	world_root = Node3D.new()
	world_viewport.add_child(world_root)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.33, 0.54, 0.83)
	sky_mat.sky_horizon_color = Color(0.69, 0.77, 0.88)
	sky_mat.ground_bottom_color = Color(0.25, 0.29, 0.23)
	sky_mat.ground_horizon_color = Color(0.48, 0.46, 0.41)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world_root.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.35
	sun.rotation_degrees = Vector3(-48.0, -36.0, 0.0)
	world_root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.35
	fill.light_color = Color(0.72, 0.80, 0.95)
	fill.rotation_degrees = Vector3(-12.0, 124.0, 0.0)
	world_root.add_child(fill)

	player_body = CharacterBody3D.new()
	player_body.name = "Player"
	world_root.add_child(player_body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.1
	collision.shape = capsule
	collision.position = Vector3(0.0, 1.0, 0.0)
	player_body.add_child(collision)

	player_camera_yaw = Node3D.new()
	player_body.add_child(player_camera_yaw)
	player_camera_pitch = Node3D.new()
	player_camera_yaw.add_child(player_camera_pitch)

	player_camera = Camera3D.new()
	player_camera.current = true
	player_camera.fov = 74.0
	player_camera.near = 0.05
	player_camera.far = 8192.0
	player_camera.position = Vector3(0.0, PLAYER_EYE_HEIGHT, 0.0)
	player_camera_pitch.add_child(player_camera)

	var can_mesh := MeshInstance3D.new()
	var can_shape := CylinderMesh.new()
	can_shape.top_radius = 0.08
	can_shape.bottom_radius = 0.1
	can_shape.height = 0.45
	can_mesh.mesh = can_shape
	can_mesh.position = Vector3(0.28, -0.22, -0.45)
	can_mesh.rotation_degrees = Vector3(86.0, 0.0, -12.0)
	var can_material := StandardMaterial3D.new()
	can_material.albedo_color = Color(0.83, 0.83, 0.80)
	can_material.metallic = 0.28
	can_mesh.material_override = can_material
	player_camera.add_child(can_mesh)


func _setup_terrain_world() -> void:
	var extension_path := "res://addons/terrain_3d/terrain.gdextension"
	if not GDExtensionManager.is_extension_loaded(extension_path):
		var load_status := GDExtensionManager.load_extension(extension_path)
		if load_status != GDExtensionManager.LOAD_STATUS_OK and load_status != GDExtensionManager.LOAD_STATUS_ALREADY_LOADED:
			push_error("Terrain3D extension failed to load. Status %s" % [load_status])
			return
	if not ClassDB.class_exists("Terrain3D"):
		push_error("Terrain3D class is unavailable. Check the addon installation.")
		return
	terrain = ClassDB.instantiate("Terrain3D")
	terrain.name = "Terrain3D"
	world_root.add_child(terrain)
	call_deferred("_finalize_terrain_world")


func _finalize_terrain_world() -> void:
	if terrain == null:
		return
	await get_tree().process_frame
	terrain_material = terrain.material
	terrain_assets = terrain.assets
	if terrain_material == null or terrain_assets == null:
		push_error("Terrain3D defaults were not ready after entering the scene tree.")
		return
	terrain_material.world_background = 0
	terrain_material.auto_shader = true
	terrain_material.set_shader_param("auto_slope", 0.22)
	terrain_material.set_shader_param("blend_sharpness", 0.88)
	terrain_material.set_shader_param("dual_scale_far", 140.0)
	terrain_material.set_shader_param("dual_scale_near", 72.0)
	terrain_material.set_shader_param("world_noise_height", 22.0)

	_assign_texture_asset(0, "Valley Grass", Color(0.28, 0.38, 0.21), Color(0.34, 0.44, 0.25), 0.03)
	_assign_texture_asset(1, "Forest Soil", Color(0.31, 0.24, 0.17), Color(0.39, 0.31, 0.22), 0.045)
	_assign_texture_asset(2, "Rock", Color(0.43, 0.44, 0.46), Color(0.55, 0.56, 0.58), 0.05)

	var height_image := _build_height_image_from_map(1024)
	terrain.region_size = 1024
	terrain.data.import_images([height_image, null, null], Vector3(-TERRAIN_SIZE.x * 0.5, 0.0, -TERRAIN_SIZE.y * 0.5), TERRAIN_HEIGHT_OFFSET, TERRAIN_HEIGHT_SCALE)
	terrain_ready = true
	_scatter_trees()
	_sync_player_body_from_map()


func _assign_texture_asset(index: int, asset_name: String, low_color: Color, high_color: Color, uv_scale: float) -> void:
	var texture_asset = ClassDB.instantiate("Terrain3DTextureAsset")
	texture_asset.name = asset_name
	texture_asset.uv_scale = uv_scale
	texture_asset.albedo_texture = _make_albedo_height_texture(low_color, high_color)
	texture_asset.normal_texture = _make_flat_normal_texture()
	terrain.assets.set_texture(index, texture_asset)


func _make_albedo_height_texture(low_color: Color, high_color: Color) -> Texture2D:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var ratio := float(y) / float(image.get_height() - 1)
			var color := low_color.lerp(high_color, ratio)
			color.a = 0.35 + ratio * 0.5
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _make_flat_normal_texture() -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 1.0, 0.85))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _build_height_image_from_map(size: int) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(MAP_PATH))
	if source == null or source.is_empty():
		source = Image.create(size, size, false, Image.FORMAT_RGB8)
		source.fill(Color(0.55, 0.55, 0.55))
	else:
		source.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var height_image := Image.create(size, size, false, Image.FORMAT_RF)
	terrain_height_min = 999999.0
	terrain_height_max = -999999.0
	for y in range(size):
		for x in range(size):
			var pixel := source.get_pixel(x, y)
			var luminance := pixel.get_luminance()
			var ridge := pow(clamp((luminance - 0.18) / 0.82, 0.0, 1.0), 2.25)
			var basin := 0.05 * sin(float(x) * 0.06) * cos(float(y) * 0.04)
			var height_value: float = clamp(ridge + basin, 0.0, 1.0)
			height_image.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))
			var world_height: float = TERRAIN_HEIGHT_OFFSET + height_value * TERRAIN_HEIGHT_SCALE
			terrain_height_min = min(terrain_height_min, world_height)
			terrain_height_max = max(terrain_height_max, world_height)
	return height_image


func _scatter_trees() -> void:
	if not terrain_ready:
		return
	tree_trunks = MultiMeshInstance3D.new()
	tree_crowns = MultiMeshInstance3D.new()
	world_root.add_child(tree_trunks)
	world_root.add_child(tree_crowns)

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 3.6
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.32, 0.23, 0.15)
	tree_trunks.multimesh = MultiMesh.new()
	tree_trunks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tree_trunks.multimesh.mesh = trunk_mesh
	trunk_mesh.material = trunk_material

	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.8
	crown_mesh.height = 4.2
	var crown_material := StandardMaterial3D.new()
	crown_material.albedo_color = Color(0.18, 0.31, 0.18)
	tree_crowns.multimesh = MultiMesh.new()
	tree_crowns.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tree_crowns.multimesh.mesh = crown_mesh
	crown_mesh.material = crown_material

	var trunk_transforms: Array[Transform3D] = []
	var crown_transforms: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var attempts := 0
	while trunk_transforms.size() < TREE_COUNT and attempts < TREE_COUNT * 12:
		attempts += 1
		var x := rng.randf_range(-TERRAIN_SIZE.x * 0.48, TERRAIN_SIZE.x * 0.48)
		var z := rng.randf_range(-TERRAIN_SIZE.y * 0.48, TERRAIN_SIZE.y * 0.48)
		var height := _terrain_height_at_world(Vector3(x, 0.0, z))
		if not is_finite(height):
			continue
		if height > TREE_LINE_ALTITUDE:
			continue
		if abs(x) < 80.0 and abs(z) < 80.0:
			continue
		var yaw := rng.randf_range(0.0, TAU)
		var scale := rng.randf_range(0.85, 1.55)
		var trunk_basis := Basis().rotated(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
		var crown_basis := Basis().rotated(Vector3.UP, yaw).scaled(Vector3(scale, scale * 1.18, scale))
		trunk_transforms.append(Transform3D(trunk_basis, Vector3(x, height + 1.8 * scale, z)))
		crown_transforms.append(Transform3D(crown_basis, Vector3(x, height + 5.0 * scale, z)))

	tree_count_actual = trunk_transforms.size()
	tree_trunks.multimesh.instance_count = tree_count_actual
	tree_crowns.multimesh.instance_count = tree_count_actual
	for i in range(tree_count_actual):
		tree_trunks.multimesh.set_instance_transform(i, trunk_transforms[i])
		tree_crowns.multimesh.set_instance_transform(i, crown_transforms[i])


func _setup_audio() -> void:
	for broadcast in BROADCAST_TEMPLATES:
		audio_stream_cache[broadcast["id"]] = _load_loopable_stream(broadcast["path"], true)
	df_voice_player = AudioStreamPlayer.new()
	add_child(df_voice_player)
	df_noise_player = AudioStreamPlayer.new()
	df_noise_player.stream = _load_loopable_stream(STATIC_WAV_PATH, true)
	add_child(df_noise_player)
	scanner_voice_player = AudioStreamPlayer.new()
	add_child(scanner_voice_player)
	df_voice_player.play()
	df_noise_player.play()
	scanner_voice_player.play()


func _process(delta: float) -> void:
	if terrain_ready:
		_update_player_motion(delta)
		_sync_map_from_player_body()
	if bearing_capture_audio_hold_timer > 0.0:
		bearing_capture_audio_hold_timer = max(0.0, bearing_capture_audio_hold_timer - delta)
		if bearing_capture_audio_hold_timer <= 0.0:
			bearing_capture_audio_hold_broadcast_id = ""
	receiver_profile = _get_df_profile()
	scanner_profile = _update_scanner(delta)
	_update_audio_mix(receiver_profile)
	_push_scope_sample(receiver_profile)
	_push_waterfall_row()
	_update_waterfall_texture()
	_update_status()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if welcome_modal.visible:
		if event is InputEventMouseButton and event.pressed:
			return
	if event is InputEventMouseMotion and mouse_capture_active:
		player_yaw -= event.relative.x * PLAYER_LOOK_SENSITIVITY
		player_pitch = clamp(player_pitch - event.relative.y * PLAYER_LOOK_SENSITIVITY * 0.7, deg_to_rad(-70.0), deg_to_rad(70.0))
		_apply_camera_rotation()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_set_mouse_capture(false)
		return
	if event.is_action_pressed("capture_bearing"):
		_capture_bearing()
	elif event.is_action_pressed("submit_fix"):
		_submit_fix()
	elif event.is_action_pressed("reset_hunt"):
		_reset_hunt()
	elif event.is_action_pressed("toggle_clean_monitor"):
		_toggle_clean_monitor()
	elif event.is_action_pressed("toggle_scanner"):
		_trigger_scanner()
	elif event.is_action_pressed("toggle_map_board"):
		_toggle_map_board()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if map_board_visible and MAP_BOARD_RECT.has_point(event.position):
			fix_position = _world_point_from_map_board(event.position)
			fix_placed = true
			result_text = "Fix marker placed from map board."
			queue_redraw()
			return
		if waterfall_display.get_global_rect().has_point(event.position):
			_tune_df_to_waterfall_click(event.position)
			return
		if PLAY_AREA.has_point(event.position):
			_set_mouse_capture(true)


func _set_mouse_capture(enabled: bool) -> void:
	mouse_capture_active = enabled and not map_board_visible and not welcome_modal.visible
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_capture_active else Input.MOUSE_MODE_VISIBLE)


func _apply_camera_rotation() -> void:
	if player_camera_yaw == null:
		return
	player_camera_yaw.rotation.y = player_yaw
	player_camera_pitch.rotation.x = player_pitch


func _update_player_motion(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var forward := Vector3(sin(player_yaw), 0.0, -cos(player_yaw))
	var right := Vector3(forward.z, 0.0, -forward.x)
	var move := (right * input_vector.x + forward * -input_vector.y) * PLAYER_MOVE_SPEED * delta
	var new_position := player_body.global_position + move
	new_position.x = clamp(new_position.x, -TERRAIN_SIZE.x * 0.48, TERRAIN_SIZE.x * 0.48)
	new_position.z = clamp(new_position.z, -TERRAIN_SIZE.y * 0.48, TERRAIN_SIZE.y * 0.48)
	new_position.y = _terrain_height_at_world(new_position)
	player_body.global_position = new_position


func _sync_player_body_from_map() -> void:
	if player_body == null:
		return
	var world_pos := _map_to_terrain(player_position)
	world_pos.y = _terrain_height_at_world(world_pos)
	player_body.global_position = world_pos
	_apply_camera_rotation()


func _sync_map_from_player_body() -> void:
	if player_body == null:
		return
	player_position = _terrain_to_map(player_body.global_position)


func _map_to_terrain(map_pos: Vector2) -> Vector3:
	var rx: float = clamp((map_pos.x - PLAY_AREA.position.x) / PLAY_AREA.size.x, 0.0, 1.0)
	var ry: float = clamp((map_pos.y - PLAY_AREA.position.y) / PLAY_AREA.size.y, 0.0, 1.0)
	return Vector3(
		lerp(-TERRAIN_SIZE.x * 0.5, TERRAIN_SIZE.x * 0.5, rx),
		0.0,
		lerp(-TERRAIN_SIZE.y * 0.5, TERRAIN_SIZE.y * 0.5, ry)
	)


func _terrain_to_map(world_pos: Vector3) -> Vector2:
	var rx: float = clamp((world_pos.x + TERRAIN_SIZE.x * 0.5) / TERRAIN_SIZE.x, 0.0, 1.0)
	var ry: float = clamp((world_pos.z + TERRAIN_SIZE.y * 0.5) / TERRAIN_SIZE.y, 0.0, 1.0)
	return Vector2(
		lerp(PLAY_AREA.position.x, PLAY_AREA.end.x, rx),
		lerp(PLAY_AREA.position.y, PLAY_AREA.end.y, ry)
	)


func _terrain_height_at_world(world_pos: Vector3) -> float:
	if terrain_ready and terrain != null:
		var height: float = terrain.data.get_height(world_pos)
		return height if is_finite(height) else 0.0
	return 0.0


func _load_map_texture() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(MAP_PATH))
	if image == null or image.is_empty():
		push_error("Unable to load map image at %s" % MAP_PATH)
		return
	map_image = image.duplicate()
	map_texture = ImageTexture.create_from_image(image)


func _dismiss_welcome_modal() -> void:
	welcome_modal.visible = false
	_set_mouse_capture(false)


func _toggle_map_board() -> void:
	map_board_visible = not map_board_visible
	_sync_overlay_visibility()
	result_text = "Map board opened." if map_board_visible else "Map board closed."
	if map_board_visible:
		_set_mouse_capture(false)


func _sync_overlay_visibility() -> void:
	panel.visible = not map_board_visible
	map_board_overlay.visible = map_board_visible


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.07, 0.09, 0.11))
	draw_rect(PLAY_AREA, Color(0.14, 0.16, 0.18), false, 2.0)
	_draw_compass()
	_draw_scope()
	if map_board_visible:
		_draw_map_board()
	if show_target and map_board_visible:
		var target_point := _map_board_point(_get_target_broadcast()["position"])
		draw_circle(target_point, 6.0, Color(1.0, 0.75, 0.26))


func _draw_compass() -> void:
	var font = _ui_font()
	draw_circle(COMPASS_CENTER, COMPASS_RADIUS + 10.0, Color(0.03, 0.05, 0.07, 0.88))
	draw_circle(COMPASS_CENTER, COMPASS_RADIUS, Color(0.10, 0.13, 0.16, 0.92))
	draw_arc(COMPASS_CENTER, COMPASS_RADIUS, 0.0, TAU, 72, Color(0.82, 0.88, 0.93, 0.48), 2.0)
	for marker in range(0, 360, 10):
		var radians = deg_to_rad(marker - 90.0)
		var outer = COMPASS_CENTER + Vector2(cos(radians), sin(radians)) * COMPASS_RADIUS
		var inner_length = COMPASS_RADIUS - (12.0 if marker % 30 == 0 else 6.0)
		var inner = COMPASS_CENTER + Vector2(cos(radians), sin(radians)) * inner_length
		draw_line(inner, outer, Color(0.80, 0.88, 0.94, 0.44), 1.5)
	for label in [0, 90, 180, 270]:
		if font == null:
			continue
		var radians = deg_to_rad(label - 90.0)
		var pos = COMPASS_CENTER + Vector2(cos(radians), sin(radians)) * (COMPASS_RADIUS - 20.0)
		var text = "N" if label == 0 else "E" if label == 90 else "S" if label == 180 else "W"
		draw_string(font, pos + Vector2(-5, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.92, 0.95, 0.98))
	var aim_vector = _get_aim_vector()
	var heading_deg = _bearing_degrees(aim_vector)
	var heading_angle = deg_to_rad(heading_deg - 90.0)
	var heading_tip = COMPASS_CENTER + Vector2(cos(heading_angle), sin(heading_angle)) * (COMPASS_RADIUS - 10.0)
	var heading_back = COMPASS_CENTER - Vector2(cos(heading_angle), sin(heading_angle)) * 18.0
	draw_line(heading_back, heading_tip, Color(0.98, 0.91, 0.42), 3.0)
	draw_line(COMPASS_CENTER, COMPASS_CENTER + Vector2(0, -COMPASS_RADIUS + 8.0), Color(0.92, 0.34, 0.28, 0.72), 2.0)
	draw_circle(COMPASS_CENTER, 5.0, Color(0.95, 0.98, 1.0))
	if font != null:
		var heading_text = "Lensatic %03d deg" % (int(round(heading_deg)) % 360)
		draw_string(font, COMPASS_CENTER + Vector2(-46, COMPASS_RADIUS + 30.0), heading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.98, 1.0))


func _draw_scope() -> void:
	draw_rect(SCOPE_RECT, Color(0.05, 0.08, 0.11))
	draw_rect(SCOPE_RECT.grow(1.0), Color(0.74, 0.83, 0.88, 0.18), false, 2.0)
	var center_y = SCOPE_RECT.position.y + SCOPE_RECT.size.y * 0.5
	draw_line(Vector2(SCOPE_RECT.position.x, center_y), Vector2(SCOPE_RECT.end.x, center_y), Color(1, 1, 1, 0.08), 1.0)
	if scope_samples.size() < 2:
		return
	var step_x = SCOPE_RECT.size.x / float(scope_samples.size() - 1)
	for i in range(scope_samples.size() - 1):
		var x1 = SCOPE_RECT.position.x + i * step_x
		var x2 = SCOPE_RECT.position.x + (i + 1) * step_x
		var y1 = center_y - scope_samples[i] * (SCOPE_RECT.size.y * 0.42)
		var y2 = center_y - scope_samples[i + 1] * (SCOPE_RECT.size.y * 0.42)
		var line_color = Color(0.54, 0.91, 0.67)
		if receiver_profile["noise_level"] > receiver_profile["voice_level"]:
			line_color = Color(0.93, 0.86, 0.44)
		draw_line(Vector2(x1, y1), Vector2(x2, y2), line_color, 2.0)


func _draw_map_board() -> void:
	draw_rect(MAP_BOARD_RECT, Color(0.93, 0.90, 0.82, 0.98))
	draw_rect(MAP_BOARD_RECT, Color(0.18, 0.13, 0.08, 0.18), false, 2.0)
	if map_texture != null:
		draw_texture_rect(map_texture, MAP_BOARD_RECT, false, Color(0.88, 0.88, 0.84, 0.82))
	_draw_map_board_grid()
	_draw_map_board_reference_ring()
	var font = _ui_font()
	for i in range(bearings.size()):
		var bearing = bearings[i]
		var origin = _map_board_point(bearing["origin"])
		var end_point = _map_board_point(bearing["origin"] + bearing["direction"] * BEARING_LENGTH)
		_draw_bearing_wedge(origin, end_point, bearing["quality"])
		draw_circle(origin, 6.0, Color(0.11, 0.22, 0.32))
		draw_line(origin, end_point, Color(0.17, 0.58, 0.84, 0.82), 2.0)
		if font != null:
			var bearing_label = "B%d %03d" % [i + 1, int(round(float(bearing.get("azimuth_deg", 0.0)))) % 360]
			draw_string(font, origin + Vector2(10, -8), bearing_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.10, 0.24, 0.34))
	var player_marker = _map_board_point(player_position)
	draw_circle(player_marker, 7.0, Color(0.28, 0.78, 0.96))
	if fix_placed:
		var fix_marker = _map_board_point(fix_position)
		draw_line(fix_marker + Vector2(-8, -8), fix_marker + Vector2(8, 8), Color(0.95, 0.34, 0.22), 2.0)
		draw_line(fix_marker + Vector2(-8, 8), fix_marker + Vector2(8, -8), Color(0.95, 0.34, 0.22), 2.0)


func _draw_map_board_grid() -> void:
	var font = _ui_font()
	for i in range(1, 4):
		var ratio = i / 4.0
		var x = lerp(MAP_BOARD_RECT.position.x, MAP_BOARD_RECT.end.x, ratio)
		var y = lerp(MAP_BOARD_RECT.position.y, MAP_BOARD_RECT.end.y, ratio)
		draw_line(Vector2(x, MAP_BOARD_RECT.position.y), Vector2(x, MAP_BOARD_RECT.end.y), Color(0.25, 0.19, 0.12, 0.12), 1.0)
		draw_line(Vector2(MAP_BOARD_RECT.position.x, y), Vector2(MAP_BOARD_RECT.end.x, y), Color(0.25, 0.19, 0.12, 0.12), 1.0)
	var north_arrow = MAP_BOARD_RECT.position + Vector2(MAP_BOARD_RECT.size.x - 32.0, 22.0)
	draw_line(north_arrow + Vector2(0, 26), north_arrow + Vector2(0, -10), Color(0.15, 0.12, 0.08), 3.0)
	draw_colored_polygon(PackedVector2Array([north_arrow + Vector2(0, -18), north_arrow + Vector2(-8, -2), north_arrow + Vector2(8, -2)]), Color(0.88, 0.26, 0.20))
	if font != null:
		draw_string(font, north_arrow + Vector2(-6, 42), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.15, 0.12, 0.08))


func _draw_map_board_reference_ring() -> void:
	var font = _ui_font()
	draw_circle(MAP_BOARD_RING_CENTER, MAP_BOARD_RING_RADIUS, Color(0.10, 0.12, 0.16, 0.18))
	draw_arc(MAP_BOARD_RING_CENTER, MAP_BOARD_RING_RADIUS, 0.0, TAU, 48, Color(0.70, 0.74, 0.82, 0.34), 2.0)
	for marker in range(0, 360, 15):
		var radians = deg_to_rad(marker - 90.0)
		var outer = MAP_BOARD_RING_CENTER + Vector2(cos(radians), sin(radians)) * MAP_BOARD_RING_RADIUS
		var inner = MAP_BOARD_RING_CENTER + Vector2(cos(radians), sin(radians)) * (MAP_BOARD_RING_RADIUS - (14.0 if marker % 45 == 0 else 7.0))
		draw_line(inner, outer, Color(0.80, 0.84, 0.91, 0.48), 1.5)
	for label in [0, 90, 180, 270]:
		var radians = deg_to_rad(label - 90.0)
		var pos = MAP_BOARD_RING_CENTER + Vector2(cos(radians), sin(radians)) * (MAP_BOARD_RING_RADIUS + 22.0)
		var text = "N" if label == 0 else "E" if label == 90 else "S" if label == 180 else "W"
		if font != null:
			draw_string(font, pos + Vector2(-6, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.86, 0.90, 0.97))


func _draw_bearing_wedge(origin: Vector2, end_point: Vector2, quality: String) -> void:
	var wedge_degrees = 18.0
	if quality == "excellent":
		wedge_degrees = 4.0
	elif quality == "good":
		wedge_degrees = 7.0
	elif quality == "usable":
		wedge_degrees = 12.0
	var bearing_vector = end_point - origin
	if bearing_vector.length() <= 0.01:
		return
	var bearing_angle = bearing_vector.angle()
	var outer_length = min(MAP_BOARD_RECT.size.x, MAP_BOARD_RECT.size.y) * 0.78
	var left_angle = bearing_angle - deg_to_rad(wedge_degrees)
	var right_angle = bearing_angle + deg_to_rad(wedge_degrees)
	var wedge_points = PackedVector2Array([
		origin,
		origin + Vector2(cos(left_angle), sin(left_angle)) * outer_length,
		origin + Vector2(cos(right_angle), sin(right_angle)) * outer_length
	])
	var wedge_color = Color(0.16, 0.62, 0.88, 0.07)
	if quality == "poor":
		wedge_color = Color(0.94, 0.70, 0.24, 0.08)
	draw_colored_polygon(wedge_points, wedge_color)


func _map_board_point(world_position: Vector2) -> Vector2:
	var ratio_x = clamp((world_position.x - PLAY_AREA.position.x) / PLAY_AREA.size.x, 0.0, 1.0)
	var ratio_y = clamp((world_position.y - PLAY_AREA.position.y) / PLAY_AREA.size.y, 0.0, 1.0)
	return Vector2(
		MAP_BOARD_RECT.position.x + ratio_x * MAP_BOARD_RECT.size.x,
		MAP_BOARD_RECT.position.y + ratio_y * MAP_BOARD_RECT.size.y
	)


func _world_point_from_map_board(board_position: Vector2) -> Vector2:
	var ratio_x = clamp((board_position.x - MAP_BOARD_RECT.position.x) / MAP_BOARD_RECT.size.x, 0.0, 1.0)
	var ratio_y = clamp((board_position.y - MAP_BOARD_RECT.position.y) / MAP_BOARD_RECT.size.y, 0.0, 1.0)
	return Vector2(
		lerp(PLAY_AREA.position.x, PLAY_AREA.end.x, ratio_x),
		lerp(PLAY_AREA.position.y, PLAY_AREA.end.y, ratio_y)
	)


func _get_aim_vector() -> Vector2:
	if testing_aim_override_enabled:
		return testing_aim_direction.normalized()
	return Vector2(sin(player_yaw), -cos(player_yaw)).normalized()


func _bearing_degrees(direction: Vector2) -> float:
	var normalized = direction.normalized()
	var degrees_value = rad_to_deg(atan2(normalized.x, -normalized.y))
	if degrees_value < 0.0:
		degrees_value += 360.0
	return degrees_value


func _ui_font():
	return status_label.get_theme_font("font") if status_label != null else null


func _capture_bearing() -> void:
	if receiver_profile["broadcast_id"] == "":
		result_text = "Tune the DF receiver onto a broadcast before taking a bearing."
		return
	var aim_vector = _get_aim_vector()
	var azimuth_deg = _bearing_degrees(aim_vector)
	var shot_number = bearings.size() + 1
	var previous_separation = 0.0 if bearings.is_empty() else player_position.distance_to(bearings[-1]["origin"])
	var advice = _bearing_capture_advice(receiver_profile["quality"], previous_separation)
	bearings.append({
		"origin": player_position,
		"direction": aim_vector,
		"frequency": df_frequency,
		"broadcast_id": receiver_profile["broadcast_id"],
		"quality": receiver_profile["quality"],
		"azimuth_deg": azimuth_deg,
		"capture_mode": "first_person",
		"shot_number": shot_number,
		"origin_separation": previous_separation,
		"advice": advice
	})
	bearing_capture_audio_hold_timer = 0.35
	bearing_capture_audio_hold_broadcast_id = receiver_profile["broadcast_id"]
	result_text = "Reading B%d %03d deg captured. %s" % [shot_number, int(round(azimuth_deg)) % 360, advice]


func _submit_fix() -> void:
	if not fix_placed:
		result_text = "Place an estimated fix on the map before submitting."
		return
	if bearings.size() < 2:
		result_text = "Capture at least two bearings before you submit a fix."
		return
	var target = _get_target_broadcast()
	var error_distance = fix_position.distance_to(target["position"])
	show_target = true
	result_text = "Submitted. Fix error: %d px. %s" % [int(round(error_distance)), _score_text(error_distance)]


func _reset_hunt() -> void:
	bearings.clear()
	result_text = ""
	show_target = false
	fix_placed = false
	fix_position = Vector2.ZERO
	map_board_visible = false
	_set_mouse_capture(false)
	smoothed_voice_level = 0.0
	smoothed_noise_level = 1.0
	df_frequency = 145.000
	scanner_active = false
	scanner_locked = false
	scanner_locked_broadcast_id = ""
	scanner_frequency = SCANNER_MIN_FREQ
	scanner_hop_timer = 0.0
	scanner_step_index = 0
	scanner_lock_strength = 0.0
	current_scanner_broadcast_id = ""
	waterfall_rows.clear()
	player_position = PLAYER_START
	player_yaw = PI * 0.5
	player_pitch = -0.08
	_reset_broadcasts()
	_sync_player_body_from_map()
	scanner_button.text = "Start Scan"
	if df_frequency_slider != null:
		df_frequency_slider.value = df_frequency
	_sync_control_labels()
	_sync_overlay_visibility()


func _update_status() -> void:
	var training_step = _current_training_step()
	var fix_text = "Fix marker placed." if fix_placed else "No fix marker."
	var last_bearing_text = "No bearing captured."
	if not bearings.is_empty():
		var last_bearing = bearings[-1]
		last_bearing_text = "Last bearing: %03d deg %s." % [int(round(last_bearing["azimuth_deg"])) % 360, String(last_bearing["quality"])]
	var scanner_text = "Scanner idle."
	if scanner_profile["state"] == "sweeping":
		scanner_text = "Scanner sweeping."
	elif scanner_profile["state"] == "locked":
		scanner_text = "Scanner locked."
	var lines := [
		"Purpose: identify target traffic, take bearings, and plot a fix.",
		training_step["title"],
		"Mode: first-person terrain",
		"DF: %.3f MHz" % df_frequency,
		scanner_text,
		"Bearings: %d" % bearings.size(),
		last_bearing_text,
		fix_text
	]
	if result_text != "":
		lines.append(result_text)
	status_label.text = "\n".join(lines)
	instructions_label.text = "%s\n%s" % [training_step["title"], training_step["detail"]]
	map_board_status_label.text = "DF %.3f MHz | Bearings %d | %s | Plot N-up" % [df_frequency, bearings.size(), fix_text]
	map_board_bearing_list.text = _map_board_bearing_summary()


func _current_training_step() -> Dictionary:
	var target_identified = receiver_profile["broadcast_id"] == TARGET_BROADCAST_ID or scanner_locked_broadcast_id == TARGET_BROADCAST_ID
	if show_target:
		return {"title": "Step 5: Review the fix", "detail": "Compare your lines with the revealed target, then reset for another run."}
	if not target_identified:
		return {"title": "Step 1: Find the real conversation", "detail": "Sweep the band, ignore educational traffic, and lock onto the target voice."}
	if bearings.is_empty():
		return {"title": "Step 2: Capture the first reading", "detail": "Settle the can antenna on the clearest heading and press Space."}
	if bearings.size() == 1:
		return {"title": "Step 3: Move and take a second reading", "detail": "Move across the terrain, then take a second line of bearing from a different position."}
	if not fix_placed:
		return {"title": "Step 4: Plot your fix", "detail": "Open the map board with M and place an estimated fix where your LOBs cross."}
	return {"title": "Step 5: Submit the fix", "detail": "Press Enter or click Submit when you are ready to score the hunt."}


func _score_text(error_distance: float) -> String:
	if error_distance < 25.0:
		return "Excellent fix."
	elif error_distance < 60.0:
		return "Good fix."
	elif error_distance < 120.0:
		return "Usable, but your bearings need refinement."
	return "Poor fix. Take bearings from more separated positions."


func _bearing_capture_advice(quality: String, previous_separation: float) -> String:
	var quality_text = quality.capitalize()
	if quality == "excellent":
		return "%s reading. Good spacing for a cross-fix." % quality_text if previous_separation >= 140.0 else "%s reading. Keep it, then move farther before the next shot." % quality_text
	if quality == "good":
		return "%s reading. Plot it and look for an intersecting line." % quality_text if previous_separation >= 140.0 else "%s reading. Usable, but widen your next position." % quality_text
	if quality == "usable":
		return "%s reading. Plot it lightly and retake if you can improve aim." % quality_text
	return "%s reading. Retake before trusting this line." % quality_text


func _reset_broadcasts() -> void:
	broadcasts.clear()
	var used_positions := []
	var used_frequencies := []
	for template in BROADCAST_TEMPLATES:
		var broadcast = template.duplicate(true)
		broadcast["position"] = _random_broadcast_position(used_positions)
		broadcast["frequency"] = _random_broadcast_frequency(used_frequencies, template["id"], template["frequency"])
		used_positions.append(broadcast["position"])
		used_frequencies.append(broadcast["frequency"])
		broadcasts.append(broadcast)


func _random_broadcast_position(used_positions: Array) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _attempt in range(40):
		var candidate = Vector2(rng.randf_range(BROADCAST_BOUNDS.position.x, BROADCAST_BOUNDS.end.x), rng.randf_range(BROADCAST_BOUNDS.position.y, BROADCAST_BOUNDS.end.y))
		var valid = candidate.distance_to(player_position) >= 220.0
		for used in used_positions:
			if candidate.distance_to(used) < 150.0:
				valid = false
		if valid:
			return candidate
	return Vector2(rng.randf_range(BROADCAST_BOUNDS.position.x, BROADCAST_BOUNDS.end.x), rng.randf_range(BROADCAST_BOUNDS.position.y, BROADCAST_BOUNDS.end.y))


func _random_broadcast_frequency(used_frequencies: Array, broadcast_id: String, fallback: float) -> float:
	if broadcast_id != TARGET_BROADCAST_ID:
		return fallback
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _attempt in range(60):
		var candidate = snappedf(rng.randf_range(144.250, 147.750), SCANNER_STEP)
		var valid := true
		for used in used_frequencies:
			if abs(candidate - used) < 0.18:
				valid = false
				break
		if valid:
			return candidate
	return fallback


func _broadcast_by_id(broadcast_id: String) -> Dictionary:
	for broadcast in broadcasts:
		if broadcast["id"] == broadcast_id:
			return broadcast
	return {}


func _get_target_broadcast() -> Dictionary:
	return _broadcast_by_id(TARGET_BROADCAST_ID)


func _active_df_broadcast() -> Dictionary:
	var best = {}
	var best_score = -1.0
	for broadcast in broadcasts:
		if abs(df_frequency - broadcast["frequency"]) > TUNE_WINDOW:
			continue
		var reading = _compute_df_signal(broadcast)
		var score = reading["clarity_base"]
		if score > best_score:
			best_score = score
			best = broadcast
	return best


func _compute_df_signal(broadcast: Dictionary) -> Dictionary:
	var to_target = broadcast["position"] - player_position
	var distance = max(to_target.length(), 0.001)
	var direction = to_target / distance
	var aim = _get_aim_vector()
	var alignment = max(aim.dot(direction), 0.0)
	var lobe = pow(alignment, 6.5)
	var distance_factor = clamp(1.0 - distance / MAX_DISTANCE, 0.0, 1.0)
	var clarity_base = distance_factor * lobe
	var voice_level = clamp(pow(clarity_base, 0.65) * 1.1, 0.0, 1.0)
	var noise_level = clamp(1.0 - voice_level * 1.1, 0.02, 1.0)
	var quality = "poor"
	if clarity_base > 0.75:
		quality = "excellent"
	elif clarity_base > 0.52:
		quality = "good"
	elif clarity_base > 0.28:
		quality = "usable"
	if distance < OVERLOAD_DISTANCE:
		voice_level *= 0.58
		noise_level = 1.0
		quality = "poor"
	return {
		"voice_level": voice_level,
		"noise_level": noise_level,
		"clarity_base": clarity_base,
		"distance": distance,
		"quality": quality
	}


func _get_df_profile() -> Dictionary:
	var active_broadcast = _active_df_broadcast()
	if active_broadcast.is_empty():
		if bearing_capture_audio_hold_timer > 0.0 and bearing_capture_audio_hold_broadcast_id != "":
			return {
				"voice_level": max(smoothed_voice_level, 0.0),
				"noise_level": max(smoothed_noise_level, 0.18),
				"quality": "captured",
				"state": "hold",
				"clarity_base": max(smoothed_voice_level, 0.0),
				"broadcast_id": bearing_capture_audio_hold_broadcast_id
			}
		smoothed_voice_level = lerp(smoothed_voice_level, 0.0, 0.22)
		smoothed_noise_level = lerp(smoothed_noise_level, 0.38, 0.18)
		return {"voice_level": smoothed_voice_level, "noise_level": smoothed_noise_level, "quality": "off-channel", "state": "retuning", "clarity_base": 0.0, "broadcast_id": ""}
	var signal_reading = _compute_df_signal(active_broadcast)
	smoothed_voice_level = lerp(smoothed_voice_level, signal_reading["voice_level"], 0.18)
	smoothed_noise_level = lerp(smoothed_noise_level, signal_reading["noise_level"], 0.15)
	return {
		"voice_level": smoothed_voice_level,
		"noise_level": smoothed_noise_level,
		"quality": signal_reading["quality"],
		"state": "overload risk" if signal_reading["distance"] < OVERLOAD_DISTANCE else "tracking",
		"clarity_base": signal_reading["clarity_base"],
		"broadcast_id": active_broadcast["id"]
	}


func _find_scanner_candidate(frequency: float) -> Dictionary:
	var best = {}
	var best_strength = -1.0
	for broadcast in broadcasts:
		if abs(frequency - broadcast["frequency"]) > TUNE_WINDOW:
			continue
		var distance_factor = clamp(1.0 - (player_position.distance_to(broadcast["position"]) / (MAX_DISTANCE * 1.1)), 0.0, 1.0)
		var strength = pow(distance_factor, 0.92)
		if strength > best_strength:
			best_strength = strength
			best = {"broadcast": broadcast, "strength": strength}
	return best


func _update_scanner(delta: float) -> Dictionary:
	if scanner_locked:
		return {"voice_level": scanner_lock_strength, "state": "locked", "frequency": scanner_frequency, "broadcast_id": scanner_locked_broadcast_id}
	if not scanner_active:
		return {"voice_level": 0.0, "state": "idle", "frequency": scanner_frequency, "broadcast_id": ""}
	scanner_hop_timer -= delta
	while scanner_hop_timer <= 0.0:
		scanner_hop_timer += 0.01
		scanner_step_index = (scanner_step_index + 1) % int(round((SCANNER_MAX_FREQ - SCANNER_MIN_FREQ) / SCANNER_STEP))
		scanner_frequency = SCANNER_MIN_FREQ + float(scanner_step_index) * SCANNER_STEP
	var candidate = _find_scanner_candidate(scanner_frequency)
	if not candidate.is_empty() and candidate["strength"] >= 0.28:
		scanner_locked = true
		scanner_active = false
		scanner_locked_broadcast_id = candidate["broadcast"]["id"]
		scanner_lock_strength = candidate["strength"]
		scanner_frequency = candidate["broadcast"]["frequency"]
		scanner_button.text = "Resume Scan"
		result_text = "Scanner locked onto %s." % candidate["broadcast"]["label"]
		return {"voice_level": scanner_lock_strength, "state": "locked", "frequency": scanner_frequency, "broadcast_id": scanner_locked_broadcast_id}
	return {"voice_level": 0.0, "state": "sweeping", "frequency": scanner_frequency, "broadcast_id": ""}


func _trigger_scanner() -> void:
	scanner_active = true
	scanner_locked = false
	scanner_locked_broadcast_id = ""
	scanner_lock_strength = 0.0
	scanner_hop_timer = 0.0
	scanner_button.text = "Scanning"
	result_text = "Scanner sweep started."


func _unlock_scanner() -> void:
	scanner_active = false
	scanner_locked = false
	scanner_locked_broadcast_id = ""
	scanner_lock_strength = 0.0
	current_scanner_broadcast_id = ""
	scanner_button.text = "Start Scan"
	result_text = "Scanner unlocked."


func _update_audio_mix(reading: Dictionary) -> void:
	if df_voice_player == null:
		return
	_update_player_stream(df_voice_player, reading["broadcast_id"], current_df_broadcast_id)
	current_df_broadcast_id = reading["broadcast_id"]
	_update_player_stream(scanner_voice_player, scanner_profile["broadcast_id"], current_scanner_broadcast_id)
	current_scanner_broadcast_id = scanner_profile["broadcast_id"]
	var voice_db = _scaled_volume_db(_broadcast_gain_db(reading["broadcast_id"]), reading["voice_level"] * df_volume)
	var noise_mix = 0.0 if clean_monitor_enabled else reading["noise_level"] * df_volume
	df_voice_player.volume_db = voice_db
	df_noise_player.volume_db = _scaled_volume_db(-6.0, noise_mix)
	scanner_voice_player.volume_db = _scaled_volume_db(_broadcast_gain_db(scanner_profile["broadcast_id"]) - 1.5, scanner_profile["voice_level"] * scanner_volume)


func _update_player_stream(player: AudioStreamPlayer, desired_broadcast_id: String, current_broadcast_id: String) -> void:
	if desired_broadcast_id == "":
		player.stream = null
		return
	if desired_broadcast_id != current_broadcast_id:
		player.stream = audio_stream_cache.get(desired_broadcast_id, null)
		player.play()
	elif not player.playing:
		player.play()


func _load_loopable_stream(path: String, should_loop: bool):
	if path.to_lower().ends_with(".mp3"):
		return _load_mp3_stream(path, should_loop)
	if path.to_lower().ends_with(".wav"):
		return _load_wav_stream(path, should_loop)
	return null


func _load_mp3_stream(path: String, should_loop: bool) -> AudioStream:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return AudioStreamMP3.new()
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	stream.loop = should_loop
	return stream


func _load_wav_stream(path: String, should_loop: bool) -> AudioStream:
	var imported = load(path)
	if imported is AudioStreamWAV:
		var stream: AudioStreamWAV = imported.duplicate()
		if should_loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return stream
	return AudioStreamWAV.new()


func _broadcast_gain_db(broadcast_id: String) -> float:
	var broadcast = _broadcast_by_id(broadcast_id)
	return float(broadcast.get("gain_db", 0.0)) if not broadcast.is_empty() else 0.0


func _scaled_volume_db(base_db: float, volume_scalar: float) -> float:
	if volume_scalar <= 0.001:
		return -80.0
	return base_db + linear_to_db(volume_scalar)


func _push_scope_sample(reading: Dictionary) -> void:
	var combined = clamp(reading["voice_level"] - reading["noise_level"] * 0.32, -1.0, 1.0)
	scope_samples.append(combined)
	while scope_samples.size() > 64:
		scope_samples.pop_front()


func _push_waterfall_row() -> void:
	var row := []
	for bin in range(WATERFALL_BINS):
		var freq = lerp(SCANNER_MIN_FREQ, SCANNER_MAX_FREQ, float(bin) / float(WATERFALL_BINS - 1))
		var intensity = 0.04
		for broadcast in broadcasts:
			var distance_factor = clamp(1.0 - player_position.distance_to(broadcast["position"]) / (MAX_DISTANCE * 1.05), 0.0, 1.0)
			var delta = abs(freq - broadcast["frequency"])
			var band = exp(-pow(delta / 0.014, 2.0))
			intensity += band * lerp(0.22, 0.92, distance_factor)
		row.append(clamp(intensity, 0.0, 1.0))
	waterfall_rows.append(row)
	while waterfall_rows.size() > WATERFALL_HISTORY:
		waterfall_rows.pop_front()


func _update_waterfall_texture() -> void:
	if waterfall_display == null:
		return
	var width = max(32, int(WATERFALL_RECT.size.x))
	var height = max(32, int(WATERFALL_RECT.size.y))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			image.set_pixel(x, y, Color(0.02, 0.03, 0.05, 1.0))
	if not waterfall_rows.is_empty():
		var row_count = waterfall_rows.size()
		var bin_count = waterfall_rows[0].size()
		for y in range(height):
			var row_ratio = float(y) / float(max(height - 1, 1))
			var source_row = int(clamp(floor((1.0 - row_ratio) * row_count), 0, row_count - 1))
			for x in range(width):
				var bin_ratio = float(x) / float(max(width - 1, 1))
				var source_bin = int(clamp(floor(bin_ratio * bin_count), 0, bin_count - 1))
				image.set_pixel(x, y, _waterfall_color(waterfall_rows[source_row][source_bin]))
	var df_ratio = (df_frequency - SCANNER_MIN_FREQ) / (SCANNER_MAX_FREQ - SCANNER_MIN_FREQ)
	var df_x = int(clamp(round(df_ratio * float(width - 1)), 0, width - 1))
	for y in range(height):
		image.set_pixel(df_x, y, Color(0.98, 0.91, 0.46, 1.0))
	var scanner_ratio = (scanner_profile["frequency"] - SCANNER_MIN_FREQ) / (SCANNER_MAX_FREQ - SCANNER_MIN_FREQ)
	var scanner_x = int(clamp(round(scanner_ratio * float(width - 1)), 0, width - 1))
	for y in range(height):
		image.set_pixel(scanner_x, y, image.get_pixel(scanner_x, y).lerp(Color(0.48, 0.82, 0.96, 1.0), 0.65))
	waterfall_texture = ImageTexture.create_from_image(image)
	waterfall_display.texture = waterfall_texture


func _waterfall_color(intensity: float) -> Color:
	var value = clamp(intensity, 0.0, 1.0)
	if value < 0.2:
		return Color(0.02, 0.06 + value * 0.18, 0.14 + value * 0.26)
	if value < 0.45:
		return Color(0.03, 0.18 + value * 0.36, 0.36 + value * 0.34)
	if value < 0.75:
		return Color(0.42 + value * 0.22, 0.52 + value * 0.14, 0.20)
	return Color(0.94, 0.82 + value * 0.1, 0.34)


func _tune_df_to_waterfall_click(screen_position: Vector2) -> void:
	var rect = waterfall_display.get_global_rect()
	var ratio = clamp((screen_position.x - rect.position.x) / max(rect.size.x, 1.0), 0.0, 1.0)
	testing_set_df_frequency(lerp(SCANNER_MIN_FREQ, SCANNER_MAX_FREQ, ratio))


func _toggle_clean_monitor() -> void:
	_on_clean_monitor_toggled(not clean_monitor_enabled)


func _on_clean_monitor_toggled(enabled: bool) -> void:
	clean_monitor_enabled = enabled
	clean_monitor_checkbox.button_pressed = enabled


func _on_df_frequency_changed(value: float) -> void:
	df_frequency = snappedf(clamp(value, SCANNER_MIN_FREQ, SCANNER_MAX_FREQ), SCANNER_STEP)
	_sync_control_labels()


func _on_df_frequency_text_entered(new_text: String) -> void:
	_apply_frequency_text(new_text)


func _on_df_frequency_focus_exited() -> void:
	_apply_frequency_text(df_frequency_input.text)


func _apply_frequency_text(raw_text: String) -> void:
	var parsed = raw_text.strip_edges().to_float()
	if parsed <= 0.0:
		_sync_control_labels()
		return
	df_frequency = snappedf(clamp(parsed, SCANNER_MIN_FREQ, SCANNER_MAX_FREQ), SCANNER_STEP)
	df_frequency_slider.value = df_frequency
	_sync_control_labels()


func _on_df_volume_changed(value: float) -> void:
	df_volume = clamp(value / 100.0, 0.0, 1.0)
	_sync_control_labels()


func _on_scanner_volume_changed(value: float) -> void:
	scanner_volume = clamp(value / 100.0, 0.0, 1.0)
	_sync_control_labels()


func _sync_control_labels() -> void:
	df_frequency_value.text = "%.3f MHz" % df_frequency
	df_frequency_input.text = "%.3f" % df_frequency
	df_volume_value.text = "%d%%" % int(round(df_volume * 100.0))
	scanner_volume_value.text = "%d%%" % int(round(scanner_volume * 100.0))


func _map_board_bearing_summary() -> String:
	if bearings.is_empty():
		return "No readings captured."
	var lines := []
	for bearing in bearings:
		lines.append("B%d  %03d  %s  %.3f MHz" % [bearing["shot_number"], int(round(bearing["azimuth_deg"])) % 360, String(bearing["quality"]).capitalize(), float(bearing["frequency"])])
	return "\n".join(lines)


func testing_dismiss_welcome_modal() -> void:
	_dismiss_welcome_modal()


func testing_set_player_position(position: Vector2) -> void:
	player_position = position
	_sync_player_body_from_map()


func testing_set_df_frequency(value: float) -> void:
	df_frequency = snappedf(clamp(value, SCANNER_MIN_FREQ, SCANNER_MAX_FREQ), SCANNER_STEP)
	df_frequency_slider.value = df_frequency
	_sync_control_labels()


func testing_set_df_frequency_text(raw_text: String) -> void:
	_apply_frequency_text(raw_text)


func testing_tune_df_from_waterfall_ratio(ratio: float) -> void:
	var rect = waterfall_display.get_global_rect()
	_tune_df_to_waterfall_click(Vector2(rect.position.x + rect.size.x * clamp(ratio, 0.0, 1.0), rect.position.y + rect.size.y * 0.5))


func testing_set_aim_direction(direction: Vector2) -> void:
	if direction.length() <= 0.001:
		testing_aim_override_enabled = false
		testing_aim_direction = Vector2.RIGHT
		return
	testing_aim_override_enabled = true
	testing_aim_direction = direction.normalized()


func testing_clear_aim_override() -> void:
	testing_aim_override_enabled = false
	testing_aim_direction = Vector2.RIGHT


func testing_capture_bearing() -> void:
	_capture_bearing()


func testing_submit_fix() -> void:
	_submit_fix()


func testing_set_fix_position(position: Vector2) -> void:
	fix_position = position
	fix_placed = true


func testing_reset_hunt() -> void:
	_reset_hunt()


func testing_trigger_scanner() -> void:
	_trigger_scanner()


func testing_unlock_scanner() -> void:
	_unlock_scanner()


func testing_toggle_map_board() -> void:
	_toggle_map_board()


func testing_place_fix_on_map_board(normalized_point: Vector2) -> void:
	var board_point = Vector2(MAP_BOARD_RECT.position.x + clamp(normalized_point.x, 0.0, 1.0) * MAP_BOARD_RECT.size.x, MAP_BOARD_RECT.position.y + clamp(normalized_point.y, 0.0, 1.0) * MAP_BOARD_RECT.size.y)
	fix_position = _world_point_from_map_board(board_point)
	fix_placed = true
	result_text = "Fix marker placed from map board."


func testing_set_clean_monitor(enabled: bool) -> void:
	_on_clean_monitor_toggled(enabled)


func testing_find_broadcast(broadcast_id: String) -> Dictionary:
	return _broadcast_by_id(broadcast_id).duplicate(true)


func testing_get_terrain_height(position: Vector2) -> float:
	return _terrain_height_at_world(_map_to_terrain(position))


func testing_get_broadcasts() -> Array:
	var out := []
	for broadcast in broadcasts:
		out.append(broadcast.duplicate(true))
	return out


func testing_snapshot() -> Dictionary:
	var last_bearing = bearings[-1].duplicate(true) if not bearings.is_empty() else {}
	return {
		"welcome_modal_visible": welcome_modal.visible,
		"player_position": player_position,
		"receiver_profile": receiver_profile.duplicate(true),
		"scanner_profile": scanner_profile.duplicate(true),
		"bearings_count": bearings.size(),
		"result_text": result_text,
		"map_board_visible": map_board_visible,
		"df_frequency": df_frequency,
		"scanner_button_text": scanner_button.text,
		"current_df_broadcast_id": current_df_broadcast_id,
		"current_scanner_broadcast_id": current_scanner_broadcast_id,
		"df_voice_volume_db": df_voice_player.volume_db if df_voice_player != null else -80.0,
		"df_stream_paused": not df_voice_player.playing if df_voice_player != null else true,
		"df_playback_position": df_voice_player.get_playback_position() if df_voice_player != null else 0.0,
		"scanner_playback_position": scanner_voice_player.get_playback_position() if scanner_voice_player != null else 0.0,
		"broadcasts": testing_get_broadcasts(),
		"last_bearing": last_bearing,
		"terrain_ready": terrain_ready,
		"terrain_height_min": terrain_height_min,
		"terrain_height_max": terrain_height_max,
		"tree_count": tree_count_actual,
		"player_world_position": player_body.global_position if player_body != null else Vector3.ZERO,
		"compass_heading_deg": _bearing_degrees(_get_aim_vector()),
		"training_step": _current_training_step(),
		"map_board_summary": {
			"has_fix": fix_placed,
			"bearing_cards": bearings.size(),
			"wedge_count": bearings.size()
		},
		"waterfall_summary": {
			"row_count": waterfall_rows.size(),
			"bin_count": WATERFALL_BINS,
			"bright_bins": _count_bright_bins(),
			"has_texture": waterfall_texture != null
		}
	}


func _count_bright_bins() -> int:
	var bright := 0
	for row in waterfall_rows:
		for value in row:
			if value >= 0.25:
				bright += 1
	return bright
