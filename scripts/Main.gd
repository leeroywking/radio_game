extends Node2D

const WORLD_SIZE := Vector2(1280, 720)
const PLAY_AREA := Rect2(Vector2(400, 40), Vector2(840, 640))
const PLAYER_SPEED := 220.0
const PLAYER_RADIUS := 10.0
const BEARING_LENGTH := 2000.0
const MAX_DISTANCE := 900.0
const OVERLOAD_DISTANCE := 70.0
const SCOPE_RECT := Rect2(Vector2(32, 204), Vector2(322, 72))
const WATERFALL_RECT := Rect2(Vector2(32, 324), Vector2(322, 92))
const WATERFALL_LABEL_HEIGHT := 18.0
const WA_HILLSHADE_PATH := "res://assets/maps/wa_hillshade.png"
const STATIC_WAV_PATH := "res://assets/audio/static_noise.wav"
const SCANNER_MIN_FREQ := 144.000
const SCANNER_MAX_FREQ := 148.000
const SCANNER_STEP := 0.005
const TUNE_WINDOW := 0.012
const TARGET_BROADCAST_ID := "real_conversation"
const WATERFALL_BINS := 72
const WATERFALL_HISTORY := 36
const BROADCAST_TEMPLATES := [
	{
		"id": "lesson_alpha",
		"label": "Educational Alpha",
		"path": "res://assets/audio/training_alpha.wav",
		"gain_db": 0.0,
		"type": "clean",
		"role": "education",
		"frequency": 144.925,
		"position": Vector2(640, 150)
	},
	{
		"id": "lesson_bravo",
		"label": "Educational Bravo",
		"path": "res://assets/audio/training_bravo.wav",
		"gain_db": 0.0,
		"type": "clean",
		"role": "education",
		"frequency": 145.410,
		"position": Vector2(1140, 560)
	},
	{
		"id": "lesson_charlie",
		"label": "Educational Charlie",
		"path": "res://assets/audio/training_charlie.wav",
		"gain_db": 0.0,
		"type": "clean",
		"role": "education",
		"frequency": 147.155,
		"position": Vector2(760, 600)
	},
	{
		"id": "real_conversation",
		"label": "Real Conversation",
		"path": "res://assets/audio/ham_contest_exchange.wav",
		"gain_db": 6.0,
		"type": "radio",
		"role": "target",
		"frequency": 146.235,
		"position": Vector2(1030, 210)
	}
]
const BROADCAST_BOUNDS := Rect2(Vector2(470, 90), Vector2(680, 520))

var player_position := Vector2(520, 560)
var fix_position = null
var result_text := ""
var show_target := false
var bearings := []
var scope_samples := []
var waterfall_rows := []
var broadcasts := []
var map_texture = null
var waterfall_texture = null

var df_voice_player = null
var df_noise_player = null
var scanner_voice_player = null
var audio_stream_cache := {}
var current_df_broadcast_id := ""
var current_scanner_broadcast_id := ""

var clean_monitor_enabled := false
var df_frequency := 145.000
var df_volume := 0.85
var scanner_volume := 0.70
var bearing_capture_audio_hold_timer := 0.0
var bearing_capture_audio_hold_broadcast_id := ""

var smoothed_voice_level := 0.0
var smoothed_noise_level := 1.0

var scanner_active := false
var scanner_locked := false
var scanner_locked_broadcast_id := ""
var scanner_frequency := SCANNER_MIN_FREQ
var scanner_hop_timer := 0.0
var scanner_step_index := 0
var scanner_lock_strength := 0.0

var receiver_profile = {
	"voice_level": 0.0,
	"noise_level": 1.0,
	"quality": "searching",
	"state": "idle",
	"clarity_base": 0.0,
	"broadcast_id": ""
}

var scanner_profile = {
	"voice_level": 0.0,
	"state": "idle",
	"frequency": SCANNER_MIN_FREQ,
	"broadcast_id": ""
}

var testing_aim_override_enabled := false
var testing_aim_direction := Vector2.RIGHT

onready var status_label := $HUD/Root/Panel/Status
onready var welcome_modal := $HUD/Root/WelcomeModal
onready var welcome_button := $HUD/Root/WelcomeModal/WelcomePanel/WelcomeButton
onready var submit_button := $HUD/Root/Panel/SubmitButton
onready var reset_button := $HUD/Root/Panel/ResetButton
onready var clean_monitor_checkbox := $HUD/Root/Panel/CleanMonitor
onready var scanner_button := $HUD/Root/Panel/ScannerButton
onready var scanner_unlock_button := $HUD/Root/Panel/ScannerUnlockButton
onready var df_frequency_slider := $HUD/Root/Panel/DFFrequencySlider
onready var df_frequency_value := $HUD/Root/Panel/DFFrequencyValue
onready var df_frequency_input := $HUD/Root/Panel/DFFrequencyInput
onready var df_volume_slider := $HUD/Root/Panel/DFVolumeSlider
onready var scanner_volume_slider := $HUD/Root/Panel/ScannerVolumeSlider
onready var df_volume_value := $HUD/Root/Panel/DFVolumeValue
onready var scanner_volume_value := $HUD/Root/Panel/ScannerVolumeValue
onready var waterfall_display := $HUD/Root/Panel/WaterfallDisplay


func _ready() -> void:
	randomize()
	_reset_broadcasts()
	_load_map_texture()
	welcome_button.connect("pressed", self, "_dismiss_welcome_modal")
	submit_button.connect("pressed", self, "_submit_fix")
	reset_button.connect("pressed", self, "_reset_hunt")
	scanner_button.connect("pressed", self, "_trigger_scanner")
	scanner_unlock_button.connect("pressed", self, "_unlock_scanner")
	clean_monitor_checkbox.connect("toggled", self, "_on_clean_monitor_toggled")
	df_frequency_slider.connect("value_changed", self, "_on_df_frequency_changed")
	df_frequency_input.connect("text_entered", self, "_on_df_frequency_text_entered")
	df_frequency_input.connect("focus_exited", self, "_on_df_frequency_focus_exited")
	df_volume_slider.connect("value_changed", self, "_on_df_volume_changed")
	scanner_volume_slider.connect("value_changed", self, "_on_scanner_volume_changed")
	clean_monitor_checkbox.pressed = clean_monitor_enabled
	df_frequency_slider.value = df_frequency
	df_volume_slider.value = df_volume * 100.0
	scanner_volume_slider.value = scanner_volume * 100.0
	_sync_control_labels()
	_setup_audio()
	set_process(true)
	set_physics_process(true)
	update()


func _physics_process(delta: float) -> void:
	var movement = Vector2.ZERO
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	movement.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if movement.length() > 1.0:
		movement = movement.normalized()
	player_position += movement * PLAYER_SPEED * delta
	player_position.x = clamp(player_position.x, PLAY_AREA.position.x + PLAYER_RADIUS, PLAY_AREA.end.x - PLAYER_RADIUS)
	player_position.y = clamp(player_position.y, PLAY_AREA.position.y + PLAYER_RADIUS, PLAY_AREA.end.y - PLAYER_RADIUS)
	update()


func _process(delta: float) -> void:
	if bearing_capture_audio_hold_timer > 0.0:
		bearing_capture_audio_hold_timer = max(0.0, bearing_capture_audio_hold_timer - delta)
		if bearing_capture_audio_hold_timer <= 0.0:
			bearing_capture_audio_hold_broadcast_id = ""
	receiver_profile = _get_df_profile()
	scanner_profile = _update_scanner(delta)
	_update_audio_mix(receiver_profile)
	_push_scope_sample(receiver_profile)
	_push_waterfall_row(delta)
	_update_waterfall_texture()
	_update_status()
	update()


func _input(event: InputEvent) -> void:
	if welcome_modal != null and welcome_modal.visible:
		if event.is_action_pressed("submit_fix") or event.is_action_pressed("capture_bearing") or event.is_action_pressed("toggle_scanner") or event.is_action_pressed("reset_hunt") or event.is_action_pressed("toggle_clean_monitor"):
			_dismiss_welcome_modal()
			get_tree().set_input_as_handled()
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
	elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if waterfall_display != null and waterfall_display.get_global_rect().has_point(event.position):
			_tune_df_to_waterfall_click(event.position)
			return
		if PLAY_AREA.has_point(event.position):
			fix_position = event.position
			update()


func _dismiss_welcome_modal() -> void:
	if welcome_modal != null:
		welcome_modal.visible = false


func _draw() -> void:
	_draw_world()
	_draw_bearings()
	_draw_fix_marker()
	_draw_player()
	_draw_scope()
	_draw_waterfall()
	if show_target:
		var target = _get_target_broadcast()
		draw_circle(target["position"], 8.0, Color(1.0, 0.45, 0.3))
		draw_arc(target["position"], 18.0, 0.0, TAU, 24, Color(1.0, 0.77, 0.3), 2.0)


func _draw_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.82, 0.83, 0.79))
	draw_rect(PLAY_AREA, Color(0.88, 0.88, 0.86))
	if map_texture != null:
		draw_texture_rect(map_texture, PLAY_AREA, false, Color(0.96, 0.96, 0.93, 1.0))
	draw_rect(PLAY_AREA, Color(0.20, 0.16, 0.10, 0.10), false, 2.0)
	for x in range(int(PLAY_AREA.position.x), int(PLAY_AREA.end.x), 80):
		draw_line(Vector2(x, PLAY_AREA.position.y), Vector2(x, PLAY_AREA.end.y), Color(0.33, 0.29, 0.18, 0.05), 1.0)
	for y in range(int(PLAY_AREA.position.y), int(PLAY_AREA.end.y), 80):
		draw_line(Vector2(PLAY_AREA.position.x, y), Vector2(PLAY_AREA.end.x, y), Color(0.33, 0.29, 0.18, 0.05), 1.0)


func _draw_player() -> void:
	var aim_vector = _get_aim_vector()
	draw_circle(player_position, PLAYER_RADIUS, Color(0.38, 0.81, 0.95))
	draw_line(player_position, player_position + aim_vector * 32.0, Color(0.98, 0.91, 0.46), 3.0)
	draw_arc(player_position, 20.0, aim_vector.angle() - 0.45, aim_vector.angle() + 0.45, 16, Color(0.98, 0.91, 0.46, 0.4), 2.0)


func _draw_bearings() -> void:
	for bearing in bearings:
		draw_circle(bearing["origin"], 4.0, Color(0.91, 0.95, 1.0))
		draw_line(bearing["origin"], bearing["origin"] + bearing["direction"] * BEARING_LENGTH, Color(0.66, 0.9, 1.0, 0.7), 2.0)


func _draw_fix_marker() -> void:
	if fix_position == null:
		return
	var color = Color(0.96, 0.4, 0.4)
	draw_line(fix_position + Vector2(-10, 0), fix_position + Vector2(10, 0), color, 3.0)
	draw_line(fix_position + Vector2(0, -10), fix_position + Vector2(0, 10), color, 3.0)
	draw_circle(fix_position, 12.0, Color(color.r, color.g, color.b, 0.1))


func _draw_scope() -> void:
	draw_rect(SCOPE_RECT, Color(0.05, 0.08, 0.11))
	draw_rect(SCOPE_RECT.grow(1.0), Color(0.74, 0.83, 0.88, 0.18), false, 2.0)
	var center_y = SCOPE_RECT.position.y + SCOPE_RECT.size.y * 0.5
	draw_line(
		Vector2(SCOPE_RECT.position.x, center_y),
		Vector2(SCOPE_RECT.end.x, center_y),
		Color(1, 1, 1, 0.08),
		1.0
	)
	if scope_samples.size() < 2:
		return
	var step_x = SCOPE_RECT.size.x / float(scope_samples.size() - 1)
	for i in range(scope_samples.size() - 1):
		var x1 = SCOPE_RECT.position.x + (i * step_x)
		var x2 = SCOPE_RECT.position.x + ((i + 1) * step_x)
		var y1 = center_y - scope_samples[i] * (SCOPE_RECT.size.y * 0.42)
		var y2 = center_y - scope_samples[i + 1] * (SCOPE_RECT.size.y * 0.42)
		var line_color = Color(0.54, 0.91, 0.67)
		if clean_monitor_enabled:
			line_color = Color(0.53, 0.77, 0.98)
		elif receiver_profile["noise_level"] > receiver_profile["voice_level"]:
			line_color = Color(0.93, 0.86, 0.44)
		draw_line(Vector2(x1, y1), Vector2(x2, y2), line_color, 2.0)


func _draw_waterfall() -> void:
	return


func _capture_bearing() -> void:
	var reading = receiver_profile
	if reading["broadcast_id"] == "":
		result_text = "Tune the DF receiver onto a broadcast before taking a bearing."
		return
	bearings.append({
		"origin": player_position,
		"direction": _get_aim_vector(),
		"frequency": df_frequency,
		"broadcast_id": reading["broadcast_id"],
		"quality": reading["quality"]
	})
	bearing_capture_audio_hold_timer = 0.35
	bearing_capture_audio_hold_broadcast_id = reading["broadcast_id"]
	result_text = "Bearing captured on %.3f MHz." % df_frequency


func _submit_fix() -> void:
	if fix_position == null:
		result_text = "Place an estimated fix on the map before submitting."
		return
	if bearings.size() < 2:
		result_text = "Capture at least two bearings before you submit a fix."
		return
	var target = _get_target_broadcast()
	var error_distance = fix_position.distance_to(target["position"])
	show_target = true
	var tuned_target = receiver_profile["broadcast_id"] == TARGET_BROADCAST_ID
	var target_text = "You are not currently tuned to the real conversation."
	if tuned_target:
		target_text = "Target frequency confirmed."
	result_text = "Submitted. Fix error: %d px. %s %s" % [int(round(error_distance)), _score_text(error_distance), target_text]


func _reset_hunt() -> void:
	bearings.clear()
	result_text = ""
	show_target = false
	fix_position = null
	smoothed_voice_level = 0.0
	smoothed_noise_level = 1.0
	scanner_active = false
	scanner_locked = false
	scanner_locked_broadcast_id = ""
	scanner_frequency = SCANNER_MIN_FREQ
	scanner_hop_timer = 0.0
	scanner_step_index = 0
	scanner_lock_strength = 0.0
	current_scanner_broadcast_id = ""
	waterfall_rows.clear()
	player_position = Vector2(520, 560)
	_reset_broadcasts()
	scanner_button.text = "Start Scan"


func _update_status() -> void:
	var fix_text = "No fix marker."
	if fix_position != null:
		fix_text = "Fix marker placed."
	var scanner_text = "Scanner idle."
	if scanner_profile["state"] == "sweeping":
		scanner_text = "Scanner sweeping."
	elif scanner_profile["state"] == "locked":
		scanner_text = "Scanner locked."
	var lines := [
		"Mission: find the real conversation and ignore the educational content.",
		"DF: %.3f MHz" % df_frequency,
		scanner_text,
		"Bearings: %d" % bearings.size(),
		fix_text
	]
	if result_text != "":
		lines.append(result_text)
	status_label.text = "\n".join(lines)


func _setup_audio() -> void:
	for broadcast in BROADCAST_TEMPLATES:
		audio_stream_cache[broadcast["id"]] = _load_wav_stream(broadcast["path"], true)
	df_voice_player = AudioStreamPlayer.new()
	df_voice_player.bus = "Master"
	add_child(df_voice_player)
	df_voice_player.play()

	df_noise_player = AudioStreamPlayer.new()
	df_noise_player.stream = _load_wav_stream(STATIC_WAV_PATH, true)
	df_noise_player.bus = "Master"
	add_child(df_noise_player)
	df_noise_player.play()

	scanner_voice_player = AudioStreamPlayer.new()
	scanner_voice_player.bus = "Master"
	add_child(scanner_voice_player)
	scanner_voice_player.play()


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


func _toggle_clean_monitor() -> void:
	clean_monitor_enabled = not clean_monitor_enabled
	clean_monitor_checkbox.pressed = clean_monitor_enabled
	var monitor_mode = "receiver"
	if clean_monitor_enabled:
		monitor_mode = "clean"
	result_text = "Monitor mode: %s." % monitor_mode


func _on_clean_monitor_toggled(pressed: bool) -> void:
	clean_monitor_enabled = pressed


func _on_df_frequency_changed(value: float) -> void:
	df_frequency = stepify(value, SCANNER_STEP)
	_sync_control_labels()


func _on_df_frequency_text_entered(new_text: String) -> void:
	_apply_frequency_text(new_text)


func _on_df_frequency_focus_exited() -> void:
	_apply_frequency_text(df_frequency_input.text)


func _on_df_volume_changed(value: float) -> void:
	df_volume = value / 100.0
	_sync_control_labels()


func _on_scanner_volume_changed(value: float) -> void:
	scanner_volume = value / 100.0
	_sync_control_labels()


func _sync_control_labels() -> void:
	df_frequency_value.text = "%.3f MHz" % df_frequency
	df_frequency_input.text = "%.3f" % df_frequency
	df_volume_value.text = "%d%%" % int(round(df_volume * 100.0))
	scanner_volume_value.text = "%d%%" % int(round(scanner_volume * 100.0))


func _apply_frequency_text(raw_text: String) -> void:
	var parsed = float(raw_text)
	if parsed == 0.0 and raw_text.strip_edges() != "0" and raw_text.strip_edges() != "0.0":
		df_frequency_input.text = "%.3f" % df_frequency
		return
	df_frequency = stepify(clamp(parsed, SCANNER_MIN_FREQ, SCANNER_MAX_FREQ), SCANNER_STEP)
	df_frequency_slider.value = df_frequency
	_sync_control_labels()


func _tune_df_to_waterfall_click(screen_position: Vector2) -> void:
	if waterfall_display == null:
		return
	var rect = waterfall_display.get_global_rect()
	if rect.size.x <= 1.0:
		return
	var ratio = clamp((screen_position.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	var tuned_frequency = stepify(lerp(SCANNER_MIN_FREQ, SCANNER_MAX_FREQ, ratio), SCANNER_STEP)
	testing_set_df_frequency(tuned_frequency)
	result_text = "DF tuned from waterfall to %.3f MHz." % df_frequency


func _load_wav_stream(path: String, should_loop: bool) -> AudioStream:
	var imported_stream = load(path)
	if imported_stream != null:
		if imported_stream is AudioStreamSample:
			var sample_stream: AudioStreamSample = imported_stream.duplicate()
			if should_loop:
				sample_stream.loop_mode = AudioStreamSample.LOOP_FORWARD
				sample_stream.loop_begin = 0
				sample_stream.loop_end = sample_stream.data.size()
			return sample_stream
		return imported_stream

	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		push_error("Unable to open WAV stream at %s" % path)
		return AudioStreamSample.new()

	var bytes = file.get_buffer(file.get_len())
	file.close()
	if bytes.size() < 44:
		push_error("WAV file too small: %s" % path)
		return AudioStreamSample.new()

	var channel_count = bytes[22] | (bytes[23] << 8)
	var sample_rate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24)
	var bits_per_sample = bytes[34] | (bytes[35] << 8)
	var data_start = 12
	var data_size = 0
	while data_start + 8 <= bytes.size():
		var chunk_id = char(bytes[data_start]) + char(bytes[data_start + 1]) + char(bytes[data_start + 2]) + char(bytes[data_start + 3])
		var chunk_size = bytes[data_start + 4] | (bytes[data_start + 5] << 8) | (bytes[data_start + 6] << 16) | (bytes[data_start + 7] << 24)
		if chunk_id == "data":
			data_start += 8
			data_size = chunk_size
			break
		data_start += 8 + chunk_size

	var sample_bytes = PoolByteArray()
	if data_size > 0 and data_start + data_size <= bytes.size():
		sample_bytes = bytes.subarray(data_start, data_start + data_size - 1)

	var stream = AudioStreamSample.new()
	stream.data = sample_bytes
	stream.mix_rate = sample_rate
	stream.stereo = channel_count == 2
	if bits_per_sample == 16:
		stream.format = AudioStreamSample.FORMAT_16_BITS
	else:
		stream.format = AudioStreamSample.FORMAT_8_BITS
	if should_loop:
		stream.loop_mode = AudioStreamSample.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(data_size / max(1, channel_count * max(1, bits_per_sample / 8)))
	return stream


func _load_map_texture() -> void:
	var imported_texture = load(WA_HILLSHADE_PATH)
	if imported_texture != null:
		map_texture = imported_texture
		return

	var image = Image.new()
	var err = image.load(WA_HILLSHADE_PATH)
	if err != OK:
		push_error("Unable to load map image at %s" % WA_HILLSHADE_PATH)
		return
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	map_texture = texture


func _get_df_profile() -> Dictionary:
	var active_broadcast = _find_df_broadcast()
	if active_broadcast.empty():
		if bearing_capture_audio_hold_timer > 0.0 and bearing_capture_audio_hold_broadcast_id != "":
			return {
				"voice_level": smoothed_voice_level,
				"noise_level": smoothed_noise_level,
				"quality": "captured",
				"state": "hold",
				"clarity_base": max(smoothed_voice_level, 0.0),
				"broadcast_id": bearing_capture_audio_hold_broadcast_id
			}
		smoothed_voice_level = lerp(smoothed_voice_level, 0.0, 0.22)
		smoothed_noise_level = lerp(smoothed_noise_level, 0.36, 0.18)
		return {
			"voice_level": smoothed_voice_level,
			"noise_level": smoothed_noise_level,
			"quality": "off-channel",
			"state": "retuning",
			"clarity_base": 0.0,
			"broadcast_id": ""
		}

	var signal = _compute_df_signal(active_broadcast)
	var voice_level = signal["voice_level"]
	var noise_level = signal["noise_level"]
	var clarity_base = signal["clarity_base"]
	smoothed_voice_level = lerp(smoothed_voice_level, voice_level, 0.2)
	smoothed_noise_level = lerp(smoothed_noise_level, noise_level, 0.18)
	voice_level = smoothed_voice_level
	noise_level = smoothed_noise_level
	var state = "tracking"
	if signal["distance"] < OVERLOAD_DISTANCE:
		state = "overload risk"
		voice_level = clamp(voice_level * 0.55, 0.0, 0.7)
		noise_level = 1.0
	if clean_monitor_enabled:
		state = "clean monitor"
		voice_level = clamp(0.35 + clarity_base * 0.65, 0.0, 1.0)
		noise_level = 0.0
	return {
		"voice_level": voice_level,
		"noise_level": noise_level,
		"quality": signal["quality"],
		"state": state,
		"clarity_base": clarity_base,
		"broadcast_id": active_broadcast["id"]
	}


func _find_df_broadcast() -> Dictionary:
	var best_broadcast = {}
	var best_score = -1.0
	for broadcast in broadcasts:
		if abs(df_frequency - broadcast["frequency"]) > TUNE_WINDOW:
			continue
		var signal = _compute_df_signal(broadcast)
		var score = signal["clarity_base"]
		if score > best_score:
			best_score = score
			best_broadcast = broadcast
	return best_broadcast


func _compute_df_signal(broadcast: Dictionary) -> Dictionary:
	var to_broadcast = broadcast["position"] - player_position
	var distance = max(to_broadcast.length(), 1.0)
	var aim_vector = _get_aim_vector()
	var direction_alignment = max(0.0, aim_vector.normalized().dot(to_broadcast.normalized()))
	var distance_factor = clamp(1.0 - (distance / MAX_DISTANCE), 0.05, 1.0)
	var clarity_base = clamp(distance_factor * pow(direction_alignment, 1.8), 0.0, 1.0)
	var time_s = OS.get_ticks_msec() * 0.001
	var slow_flutter = 0.84 + 0.08 * sin(time_s * 1.1) + 0.05 * sin(time_s * 2.7 + 0.7)
	var fast_flutter = 0.06 * sin(time_s * 8.2 + player_position.x * 0.01) + 0.04 * sin(time_s * 13.7 + player_position.y * 0.015)
	var drift = 0.05 * sin(time_s * 0.43 + distance * 0.004)
	var analog_variation = clamp(slow_flutter + fast_flutter + drift, 0.72, 1.05)
	var alignment_gate = clamp((direction_alignment - 0.84) / 0.16, 0.0, 1.0)
	var distance_gate = clamp((distance_factor - 0.08) / 0.92, 0.0, 1.0)
	var voice_level = clamp(pow(alignment_gate, 2.2) * pow(distance_gate, 0.78) * analog_variation, 0.0, 1.0)
	var noise_floor = 0.08
	if broadcast["type"] == "clean":
		noise_floor = 0.0
	var dither = rand_range(-0.008, 0.008)
	voice_level = _analogize_level(voice_level, 100, dither)
	var noise_level = clamp(
		0.52
		- voice_level * 0.82
		+ (1.0 - distance_factor) * 0.08
		+ (1.0 - direction_alignment) * 0.32
		+ noise_floor,
		0.0,
		0.75
	)
	noise_level = _analogize_level(noise_level, 100, -dither * 0.7)
	if direction_alignment < 0.78:
		voice_level = 0.0
		noise_level = min(0.62 + (0.78 - direction_alignment) * 0.4, 0.92)
	if clarity_base > 0.72 and direction_alignment > 0.95:
		noise_level = 0.0
		voice_level = max(voice_level, 0.92)
	var quality = "poor"
	if direction_alignment > 0.96 and distance_factor > 0.42:
		quality = "excellent"
	elif direction_alignment > 0.84 and distance_factor > 0.24:
		quality = "good"
	elif direction_alignment > 0.55:
		quality = "usable"
	return {
		"voice_level": voice_level,
		"noise_level": noise_level,
		"clarity_base": clarity_base,
		"quality": quality,
		"distance": distance
	}


func _update_scanner(delta: float) -> Dictionary:
	var state = "idle"
	var locked_broadcast = {}
	if scanner_locked:
		locked_broadcast = _broadcast_by_id(scanner_locked_broadcast_id)
		if locked_broadcast.empty():
			_unlock_scanner()
		else:
			var distance_factor = clamp(1.0 - (player_position.distance_to(locked_broadcast["position"]) / (MAX_DISTANCE * 1.1)), 0.0, 1.0)
			scanner_lock_strength = lerp(scanner_lock_strength, pow(distance_factor, 0.92), 0.1)
			scanner_frequency = locked_broadcast["frequency"]
			state = "locked"
	if scanner_active and not scanner_locked:
		state = "sweeping"
		scanner_hop_timer += delta
		if scanner_hop_timer >= 0.12:
			scanner_hop_timer = 0.0
			var step_count = int(round((SCANNER_MAX_FREQ - SCANNER_MIN_FREQ) / SCANNER_STEP))
			var safe_step_count = max(step_count, 1)
			scanner_step_index = int((scanner_step_index + 7) % safe_step_count)
			scanner_frequency = SCANNER_MIN_FREQ + scanner_step_index * SCANNER_STEP
			var candidate = _find_scanner_candidate(scanner_frequency)
			if not candidate.empty() and candidate["strength"] > 0.24:
				scanner_locked = true
				scanner_locked_broadcast_id = candidate["broadcast"]["id"]
				scanner_lock_strength = candidate["strength"]
				scanner_frequency = candidate["broadcast"]["frequency"]
				state = "locked"
				result_text = "Scanner locked at %.3f MHz." % scanner_frequency
	if not scanner_active and not scanner_locked:
		scanner_frequency = SCANNER_MIN_FREQ
	if scanner_locked:
		scanner_button.text = "Rescan"
	elif scanner_active:
		scanner_button.text = "Scanning"
	else:
		scanner_button.text = "Start Scan"
	var scanner_voice_level = 0.0
	var scanner_broadcast_id = ""
	if scanner_locked:
		scanner_voice_level = scanner_lock_strength
		scanner_broadcast_id = scanner_locked_broadcast_id
	return {
		"voice_level": scanner_voice_level,
		"state": state,
		"frequency": scanner_frequency,
		"broadcast_id": scanner_broadcast_id
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
			best = {
				"broadcast": broadcast,
				"strength": strength
			}
	return best


func _get_aim_vector() -> Vector2:
	if testing_aim_override_enabled and testing_aim_direction.length() > 0.001:
		return testing_aim_direction.normalized()
	var aim = get_viewport().get_mouse_position() - player_position
	if aim.length() < 0.001:
		return Vector2.RIGHT
	return aim.normalized()


func _score_text(error_distance: float) -> String:
	if error_distance < 25.0:
		return "Excellent fix."
	elif error_distance < 60.0:
		return "Good fix."
	elif error_distance < 120.0:
		return "Usable, but your bearings need refinement."
	return "Poor fix. Take bearings from more separated positions."


func _update_audio_mix(reading: Dictionary) -> void:
	if df_voice_player == null or df_noise_player == null or scanner_voice_player == null:
		return
	_update_player_stream(df_voice_player, reading["broadcast_id"], current_df_broadcast_id)
	current_df_broadcast_id = reading["broadcast_id"]
	_update_player_stream(scanner_voice_player, scanner_profile["broadcast_id"], current_scanner_broadcast_id)
	current_scanner_broadcast_id = scanner_profile["broadcast_id"]

	var voice_level = reading["voice_level"]
	var noise_level = reading["noise_level"]
	var clarity_base = float(reading.get("clarity_base", voice_level))
	var df_gain_db = _broadcast_gain_db(reading["broadcast_id"])
	if reading["broadcast_id"] == "":
		df_voice_player.volume_db = -80.0
	elif clean_monitor_enabled:
		var clean_presence = clamp(max(voice_level, 0.4 + clarity_base * 0.6), 0.0, 1.0)
		df_voice_player.volume_db = _scaled_volume_db(lerp(-8.5, -1.5, clean_presence) + df_gain_db, df_volume)
	elif voice_level < 0.06:
		df_voice_player.volume_db = _scaled_volume_db(-20.0 + df_gain_db, df_volume)
	else:
		var consistency_presence = clamp(max(clarity_base, voice_level * 0.7 + clarity_base * 0.3), 0.0, 1.0)
		var consistency_penalty = clamp((noise_level - voice_level) * 1.8, 0.0, 1.0) * 1.5
		var voice_target_db = lerp(-8.5, -2.5, consistency_presence) - consistency_penalty
		df_voice_player.volume_db = _scaled_volume_db(voice_target_db + df_gain_db, df_volume)
	if noise_level <= 0.001:
		df_noise_player.volume_db = -80.0
	else:
		df_noise_player.volume_db = _scaled_volume_db(lerp(-42.0, -16.0, noise_level), df_volume)
	df_voice_player.pitch_scale = 0.96 + voice_level * 0.08

	var scanner_level = scanner_profile["voice_level"]
	var scanner_gain_db = _broadcast_gain_db(scanner_profile["broadcast_id"])
	if scanner_profile["broadcast_id"] == "":
		scanner_voice_player.volume_db = -80.0
	else:
		scanner_voice_player.volume_db = _scaled_volume_db(lerp(-20.0, -2.0, scanner_level) + scanner_gain_db, scanner_volume)
	scanner_voice_player.pitch_scale = 1.0


func _update_player_stream(player: AudioStreamPlayer, broadcast_id: String, current_id: String) -> void:
	if broadcast_id == current_id:
		if broadcast_id == "":
			if player.playing:
				player.stop()
			return
		if player.stream == null:
			player.stream = audio_stream_cache.get(broadcast_id, null)
		if not player.playing and player.stream != null:
			player.play()
		return
	player.stop()
	if broadcast_id == "":
		player.stream = null
	else:
		player.stream = audio_stream_cache[broadcast_id]
	player.play()


func _push_scope_sample(reading: Dictionary) -> void:
	var t = 0.0
	if df_voice_player != null:
		t = df_voice_player.get_playback_position()
	var voice_level = reading["voice_level"]
	var noise_level = reading["noise_level"]
	var voice_envelope = 0.45 + 0.3 * sin(t * 8.0) + 0.2 * sin(t * 15.7 + 0.8) + 0.08 * sin(t * 28.3)
	voice_envelope = clamp(voice_envelope, 0.05, 1.0)
	var structured = voice_level * voice_envelope * sin(t * 42.0)
	var hiss = noise_level * rand_range(-0.95, 0.95)
	var hiss_weight = 0.2 + noise_level * 0.55
	if clean_monitor_enabled:
		hiss_weight = 0.0
	if noise_level <= 0.001:
		hiss_weight = 0.0
	var mixed = clamp(structured + hiss * hiss_weight, -1.0, 1.0)
	scope_samples.append(mixed)
	if scope_samples.size() > 120:
		scope_samples.pop_front()


func _push_waterfall_row(delta: float) -> void:
	var row = []
	var t = OS.get_ticks_msec() * 0.001
	for bin_index in range(WATERFALL_BINS):
		var ratio = float(bin_index) / float(max(WATERFALL_BINS - 1, 1))
		var frequency = lerp(SCANNER_MIN_FREQ, SCANNER_MAX_FREQ, ratio)
		var ambient_floor = 0.035 + 0.018 * sin(t * 0.65 + ratio * 9.0)
		var ripple = 0.014 * sin(t * 5.4 + ratio * 34.0 + sin(t * 0.8))
		var sparkle = rand_range(0.0, 0.014)
		var intensity = ambient_floor + ripple + sparkle
		for broadcast in broadcasts:
			intensity += _waterfall_signal_energy(broadcast, frequency, t)
		row.append(clamp(intensity, 0.0, 1.0))
	waterfall_rows.append(row)
	if waterfall_rows.size() > WATERFALL_HISTORY:
		waterfall_rows.pop_front()


func _waterfall_signal_energy(broadcast: Dictionary, frequency: float, t: float) -> float:
	var frequency_delta = abs(frequency - broadcast["frequency"])
	var to_broadcast = broadcast["position"] - player_position
	var distance_factor = clamp(1.0 - (to_broadcast.length() / (MAX_DISTANCE * 1.15)), 0.02, 1.0)
	var base_strength = pow(distance_factor, 0.62)
	var role_gain = 0.38
	if broadcast["role"] == "target":
		role_gain = 0.52
	var activity = 0.82 + 0.2 * sin(t * 2.6 + broadcast["frequency"] * 1.7) + 0.12 * sin(t * 7.8 + broadcast["position"].x * 0.01)
	var center_width = 0.026
	var shoulder_width = 0.060
	var center_peak = exp(-pow(frequency_delta / center_width, 2.0))
	var shoulder_peak = exp(-pow(frequency_delta / shoulder_width, 2.0))
	var dynamic_gain = base_strength * role_gain * activity
	return center_peak * dynamic_gain + shoulder_peak * dynamic_gain * 0.34


func _update_waterfall_texture() -> void:
	if waterfall_display == null:
		return
	var width = int(max(1.0, waterfall_display.rect_size.x))
	var height = int(max(1.0, waterfall_display.rect_size.y))
	var image = Image.new()
	image.create(width, height, false, Image.FORMAT_RGBA8)
	image.lock()
	for y in range(height):
		for x in range(width):
			image.set_pixel(x, y, Color(0.02, 0.03, 0.05, 1.0))
	if not waterfall_rows.empty():
		var row_count = waterfall_rows.size()
		var bin_count = waterfall_rows[0].size()
		for y in range(height):
			var row_ratio = float(y) / float(max(height - 1, 1))
			var source_row = int(clamp(floor((1.0 - row_ratio) * row_count), 0, row_count - 1))
			for x in range(width):
				var bin_ratio = float(x) / float(max(width - 1, 1))
				var source_bin = int(clamp(floor(bin_ratio * bin_count), 0, bin_count - 1))
				var intensity = waterfall_rows[source_row][source_bin]
				image.set_pixel(x, y, _waterfall_color(intensity))
	var df_ratio = (df_frequency - SCANNER_MIN_FREQ) / (SCANNER_MAX_FREQ - SCANNER_MIN_FREQ)
	var df_x = int(clamp(round(df_ratio * float(width - 1)), 0, width - 1))
	for y in range(height):
		image.set_pixel(df_x, y, Color(0.98, 0.91, 0.46, 1.0))
	var scanner_ratio = (scanner_profile["frequency"] - SCANNER_MIN_FREQ) / (SCANNER_MAX_FREQ - SCANNER_MIN_FREQ)
	var scanner_x = int(clamp(round(scanner_ratio * float(width - 1)), 0, width - 1))
	for y in range(height):
		var blended = image.get_pixel(scanner_x, y).linear_interpolate(Color(0.48, 0.82, 0.96, 1.0), 0.65)
		image.set_pixel(scanner_x, y, blended)
	image.unlock()
	if waterfall_texture == null:
		waterfall_texture = ImageTexture.new()
	waterfall_texture.create_from_image(image, 0)
	waterfall_display.texture = waterfall_texture


func _audio_summary(reading: Dictionary) -> String:
	var voice_level = reading["voice_level"]
	var noise_level = reading["noise_level"]
	if reading["broadcast_id"] == "":
		return "off-channel"
	if clean_monitor_enabled:
		return "clean source"
	if reading["state"] == "overload risk":
		return "blown out"
	if noise_level < 0.02 and voice_level > 0.88:
		return "full quieting"
	if voice_level > 0.72 and noise_level < 0.35:
		return "clear copy"
	if voice_level > 0.42:
		return "rough copy"
	if voice_level > 0.16:
		return "fragmented"
	return "static only"


func _analogize_level(value: float, step_count: int, dither: float) -> float:
	var clamped = clamp(value + dither, 0.0, 1.0)
	var stepped = round(clamped * step_count) / float(step_count)
	var overlap = clamp(value * 0.65 + stepped * 0.35 + dither * 0.6, 0.0, 1.0)
	return overlap


func _scaled_volume_db(base_db: float, volume_scalar: float) -> float:
	if volume_scalar <= 0.001:
		return -80.0
	return base_db + linear2db(volume_scalar)


func _broadcast_gain_db(broadcast_id: String) -> float:
	if broadcast_id == "":
		return 0.0
	var broadcast = _broadcast_by_id(broadcast_id)
	if broadcast.empty():
		return 0.0
	return float(broadcast.get("gain_db", 0.0))


func _waterfall_color(intensity: float) -> Color:
	var value = clamp(intensity, 0.0, 1.0)
	if value < 0.2:
		return Color(0.02, 0.06 + value * 0.18, 0.14 + value * 0.26)
	if value < 0.45:
		return Color(0.03, 0.18 + value * 0.36, 0.36 + value * 0.34)
	if value < 0.75:
		return Color(0.42 + value * 0.22, 0.52 + value * 0.14, 0.20)
	return Color(0.94, 0.82 + value * 0.1, 0.34)


func _label_for_broadcast(broadcast_id: String) -> String:
	if broadcast_id == "":
		return "none"
	var broadcast = _broadcast_by_id(broadcast_id)
	if broadcast.empty():
		return "none"
	return broadcast["label"]


func _broadcast_by_id(broadcast_id: String) -> Dictionary:
	for broadcast in broadcasts:
		if broadcast["id"] == broadcast_id:
			return broadcast
	return {}


func _get_target_broadcast() -> Dictionary:
	return _broadcast_by_id(TARGET_BROADCAST_ID)


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
	var attempt = 0
	while attempt < 40:
		var candidate = Vector2(
			rand_range(BROADCAST_BOUNDS.position.x, BROADCAST_BOUNDS.end.x),
			rand_range(BROADCAST_BOUNDS.position.y, BROADCAST_BOUNDS.end.y)
		)
		var valid = true
		for used in used_positions:
			if candidate.distance_to(used) < 150.0:
				valid = false
				break
		if candidate.distance_to(player_position) < 220.0:
			valid = false
		if valid:
			return candidate
		attempt += 1
	return Vector2(
		rand_range(BROADCAST_BOUNDS.position.x, BROADCAST_BOUNDS.end.x),
		rand_range(BROADCAST_BOUNDS.position.y, BROADCAST_BOUNDS.end.y)
	)


func _random_broadcast_frequency(used_frequencies: Array, broadcast_id: String, fallback: float) -> float:
	var min_spacing = 0.18
	var base_min = 144.250
	var base_max = 147.750
	if broadcast_id != TARGET_BROADCAST_ID:
		return fallback
	var attempt = 0
	while attempt < 60:
		var candidate = stepify(rand_range(base_min, base_max), SCANNER_STEP)
		var valid = true
		for used in used_frequencies:
			if abs(candidate - used) < min_spacing:
				valid = false
				break
		if valid:
			return candidate
		attempt += 1
	return fallback


func testing_set_player_position(position: Vector2) -> void:
	player_position = position


func testing_set_df_frequency(value: float) -> void:
	df_frequency = stepify(clamp(value, SCANNER_MIN_FREQ, SCANNER_MAX_FREQ), SCANNER_STEP)
	if df_frequency_slider != null:
		df_frequency_slider.value = df_frequency
	_sync_control_labels()


func testing_tune_df_from_waterfall_ratio(ratio: float) -> void:
	if waterfall_display == null:
		return
	var rect = waterfall_display.get_global_rect()
	var clamped_ratio = clamp(ratio, 0.0, 1.0)
	var click_position = Vector2(
		rect.position.x + rect.size.x * clamped_ratio,
		rect.position.y + rect.size.y * 0.5
	)
	_tune_df_to_waterfall_click(click_position)


func testing_set_df_frequency_text(raw_text: String) -> void:
	_apply_frequency_text(raw_text)


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


func testing_set_fix_position(position: Vector2) -> void:
	fix_position = position


func testing_capture_bearing() -> void:
	_capture_bearing()


func testing_submit_fix() -> void:
	_submit_fix()


func testing_reset_hunt() -> void:
	_reset_hunt()


func testing_trigger_scanner() -> void:
	_trigger_scanner()


func testing_unlock_scanner() -> void:
	_unlock_scanner()


func testing_set_clean_monitor(enabled: bool) -> void:
	clean_monitor_enabled = enabled
	if clean_monitor_checkbox != null:
		clean_monitor_checkbox.pressed = enabled


func testing_dismiss_welcome_modal() -> void:
	_dismiss_welcome_modal()


func testing_get_broadcasts() -> Array:
	var copy := []
	for broadcast in broadcasts:
		copy.append(broadcast.duplicate(true))
	return copy


func testing_find_broadcast(broadcast_id: String) -> Dictionary:
	return _broadcast_by_id(broadcast_id).duplicate(true)


func testing_snapshot() -> Dictionary:
	var waterfall_summary = testing_get_waterfall_summary()
	return {
		"player_position": player_position,
		"df_frequency": df_frequency,
		"result_text": result_text,
		"bearings_count": bearings.size(),
		"fix_position": fix_position,
		"receiver_profile": receiver_profile.duplicate(true),
		"scanner_profile": scanner_profile.duplicate(true),
		"current_df_broadcast_id": current_df_broadcast_id,
		"current_scanner_broadcast_id": current_scanner_broadcast_id,
		"df_playback_position": df_voice_player.get_playback_position() if df_voice_player != null else 0.0,
		"scanner_playback_position": scanner_voice_player.get_playback_position() if scanner_voice_player != null else 0.0,
		"df_stream_paused": not df_voice_player.playing if df_voice_player != null else true,
		"scanner_stream_paused": not scanner_voice_player.playing if scanner_voice_player != null else true,
		"df_voice_volume_db": df_voice_player.volume_db if df_voice_player != null else -80.0,
		"df_noise_volume_db": df_noise_player.volume_db if df_noise_player != null else -80.0,
		"scanner_voice_volume_db": scanner_voice_player.volume_db if scanner_voice_player != null else -80.0,
		"df_has_stream": df_voice_player != null and df_voice_player.stream != null,
		"welcome_modal_visible": welcome_modal != null and welcome_modal.visible,
		"broadcasts": testing_get_broadcasts(),
		"waterfall_summary": waterfall_summary
	}


func testing_get_waterfall_summary() -> Dictionary:
	var row_count = waterfall_rows.size()
	var bin_count = 0
	var max_intensity = 0.0
	var avg_intensity = 0.0
	var bright_bins = 0
	var sample_count = 0
	if row_count > 0:
		bin_count = waterfall_rows[0].size()
	for row in waterfall_rows:
		for value in row:
			var sample = float(value)
			max_intensity = max(max_intensity, sample)
			avg_intensity += sample
			sample_count += 1
			if sample >= 0.25:
				bright_bins += 1
	if sample_count > 0:
		avg_intensity /= float(sample_count)
	return {
		"row_count": row_count,
		"bin_count": bin_count,
		"max_intensity": max_intensity,
		"average_intensity": avg_intensity,
		"bright_bins": bright_bins,
		"has_texture": waterfall_texture != null and waterfall_display != null and waterfall_display.texture != null
	}


func testing_get_waterfall_intensity_at_frequency(frequency: float) -> float:
	if waterfall_rows.empty():
		return 0.0
	var ratio = (frequency - SCANNER_MIN_FREQ) / (SCANNER_MAX_FREQ - SCANNER_MIN_FREQ)
	var bin_index = int(clamp(round(ratio * float(max(WATERFALL_BINS - 1, 1))), 0, WATERFALL_BINS - 1))
	var total = 0.0
	var samples = 0
	for row in waterfall_rows:
		total += float(row[bin_index])
		samples += 1
	return total / float(max(samples, 1))
