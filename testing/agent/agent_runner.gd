extends SceneTree

const PROJECT_REPORT_DIR := "res://testing/reports"
const LATEST_JSON_PATH := PROJECT_REPORT_DIR + "/latest.json"
const PREVIOUS_JSON_PATH := PROJECT_REPORT_DIR + "/previous.json"
const LATEST_MD_PATH := PROJECT_REPORT_DIR + "/latest.md"
const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
const TARGET_ID := "real_conversation"

var game = null
var latest_report := {}
var previous_report = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load(MAIN_SCENE_PATH)
	if scene == null:
		push_error("Unable to load main scene.")
		quit(1)
		return

	game = scene.instantiate()
	root.add_child(game)
	await _wait_seconds(0.45).timeout

	previous_report = _load_json(PREVIOUS_JSON_PATH)
	latest_report = {
		"generated_at": Time.get_datetime_dict_from_system(true),
		"engine_version": Engine.get_version_info(),
		"cases": [],
		"summary": {},
		"comparison_to_previous": []
	}

	var cases: Array = []
	cases.append(await _run_startup_modal_case())
	cases.append(await _run_terrain_bootstrap_case())
	cases.append(await _run_terrain_import_profile_case())
	cases.append(await _run_terrain_scale_case())
	cases.append(await _run_terrain_variation_case())
	cases.append(await _run_first_person_forward_motion_case())
	cases.append(await _run_waterfall_visibility_case())
	cases.append(await _run_waterfall_click_tuning_case())
	cases.append(await _run_scanner_lock_case())
	cases.append(await _run_bearing_capture_case())
	cases.append(await _run_map_board_fix_case())
	cases.append(await _run_df_audio_case())

	var pass_count := 0
	var warning_count := 0
	var exit_code := 0
	for case_result in cases:
		latest_report["cases"].append(case_result)
		if case_result.get("pass", false):
			pass_count += 1
		else:
			exit_code = 2
		if case_result.get("warning", false):
			warning_count += 1

	latest_report["summary"] = {
		"case_count": cases.size(),
		"pass_count": pass_count,
		"warning_count": warning_count,
		"failed_count": cases.size() - pass_count
	}
	latest_report["comparison_to_previous"] = _compare_to_previous(latest_report, previous_report)
	_write_reports(latest_report)
	if is_instance_valid(game):
		game.queue_free()
	await _wait_seconds(0.1).timeout
	quit(exit_code)


func _run_startup_modal_case() -> Dictionary:
	var before = game.testing_snapshot()
	var initially_visible := bool(before.get("welcome_modal_visible", false))
	game.testing_dismiss_welcome_modal()
	await _wait_seconds(0.05).timeout
	var after = game.testing_snapshot()
	return {
		"name": "startup_modal",
		"pass": initially_visible and not bool(after.get("welcome_modal_visible", true)),
		"warning": false,
		"details": {
			"initially_visible": initially_visible,
			"dismissed": not bool(after.get("welcome_modal_visible", true))
		}
	}


func _run_terrain_bootstrap_case() -> Dictionary:
	game.testing_dismiss_welcome_modal()
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var ready := bool(snapshot.get("terrain_ready", false))
	var terrain_backend := String(snapshot.get("terrain_backend", ""))
	var tree_count := int(snapshot.get("tree_count", 0))
	var height_min := float(snapshot.get("terrain_height_min", 0.0))
	var height_max := float(snapshot.get("terrain_height_max", 0.0))
	return {
		"name": "terrain_bootstrap",
		"pass": ready and terrain_backend == "builtin_mesh" and tree_count >= 120 and height_max > height_min + 40.0,
		"warning": false,
		"details": {
			"terrain_ready": ready,
			"terrain_backend": terrain_backend,
			"tree_count": tree_count,
			"terrain_height_min": height_min,
			"terrain_height_max": height_max
		}
	}


func _run_terrain_import_profile_case() -> Dictionary:
	game.testing_dismiss_welcome_modal()
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var terrain_import: Dictionary = snapshot.get("terrain_import", {})
	var source_path := String(terrain_import.get("source_path", ""))
	var mode := String(terrain_import.get("mode", ""))
	var profile_id := String(terrain_import.get("profile_id", ""))
	return {
		"name": "terrain_import_profile",
		"pass": profile_id == "wa_hillshade_demo" and mode == "hillshade_reconstruction" and source_path.ends_with("wa_hillshade.png"),
		"warning": false,
		"details": terrain_import
	}


func _run_terrain_scale_case() -> Dictionary:
	game.testing_dismiss_welcome_modal()
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var world_size_km: Vector2 = snapshot.get("terrain_world_size_km", Vector2.ZERO)
	var world_size_m: Vector2 = snapshot.get("terrain_world_size_m", Vector2.ZERO)
	var crossing_seconds := float(snapshot.get("estimated_crossing_seconds", 0.0))
	var tree_profile: Dictionary = snapshot.get("tree_profile", {})
	return {
		"name": "terrain_scale",
		"pass": world_size_km.x >= 24.0 and world_size_km.y >= 18.0 and world_size_m.x >= 24000.0 and crossing_seconds >= 75.0 and float(tree_profile.get("trunk_height", 0.0)) >= 8.0,
		"warning": false,
		"details": {
			"terrain_world_size_km": world_size_km,
			"terrain_world_size_m": world_size_m,
			"estimated_crossing_seconds": crossing_seconds,
			"tree_profile": tree_profile
		}
	}


func _run_terrain_variation_case() -> Dictionary:
	var samples := [
		Vector2(520, 560),
		Vector2(660, 240),
		Vector2(1020, 180),
		Vector2(1160, 600)
	]
	var heights: Array = []
	for sample in samples:
		heights.append(game.testing_get_terrain_height(sample))
	var min_height: float = float(heights[0])
	var max_height: float = float(heights[0])
	for value in heights:
		min_height = min(min_height, float(value))
		max_height = max(max_height, float(value))
	return {
		"name": "terrain_variation",
		"pass": max_height > min_height + 60.0,
		"warning": false,
		"details": {
			"heights": heights,
			"min_height": min_height,
			"max_height": max_height
		}
	}


func _run_first_person_forward_motion_case() -> Dictionary:
	game.testing_reset_hunt()
	game.testing_dismiss_welcome_modal()
	game.testing_set_player_position(Vector2(820, 430))
	game.testing_set_player_yaw(0.0)
	await _wait_seconds(0.05).timeout
	var before = game.testing_snapshot()
	game.testing_step_forward(80.0)
	await _wait_seconds(0.05).timeout
	var after = game.testing_snapshot()
	var before_pos: Vector3 = before.get("player_world_position", Vector3.ZERO)
	var after_pos: Vector3 = after.get("player_world_position", Vector3.ZERO)
	var heading_deg := float(after.get("compass_heading_deg", 0.0))
	return {
		"name": "first_person_forward_motion",
		"pass": after_pos.z < before_pos.z - 20.0 and abs(heading_deg) <= 1.0,
		"warning": false,
		"details": {
			"before_world": before_pos,
			"after_world": after_pos,
			"heading_deg": heading_deg
		}
	}


func _run_waterfall_visibility_case() -> Dictionary:
	await _wait_seconds(0.35).timeout
	var snapshot = game.testing_snapshot()
	var waterfall = snapshot.get("waterfall_summary", {})
	return {
		"name": "waterfall_visibility",
		"pass": bool(waterfall.get("has_texture", false)) and int(waterfall.get("row_count", 0)) >= 8 and int(waterfall.get("bright_bins", 0)) > 0,
		"warning": false,
		"details": waterfall
	}


func _run_waterfall_click_tuning_case() -> Dictionary:
	game.testing_tune_df_from_waterfall_ratio(0.5)
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var tuned_frequency := float(snapshot.get("df_frequency", 0.0))
	return {
		"name": "waterfall_click_tuning",
		"pass": abs(tuned_frequency - 146.0) <= 0.03,
		"warning": false,
		"details": {
			"df_frequency": tuned_frequency
		}
	}


func _run_scanner_lock_case() -> Dictionary:
	game.testing_reset_hunt()
	game.testing_dismiss_welcome_modal()
	var target = game.testing_find_broadcast(TARGET_ID)
	game.testing_set_player_position(target["position"] + Vector2(-150, 20))
	game.testing_trigger_scanner()
	await _wait_seconds(3.2).timeout
	var snapshot = game.testing_snapshot()
	var profile = snapshot.get("scanner_profile", {})
	return {
		"name": "scanner_lock",
		"pass": String(profile.get("state", "")) == "locked" and String(profile.get("broadcast_id", "")) != "",
		"warning": false,
		"details": profile
	}


func _run_bearing_capture_case() -> Dictionary:
	game.testing_reset_hunt()
	game.testing_dismiss_welcome_modal()
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position: Vector2 = target["position"] + Vector2(-180, 0)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	await _wait_seconds(0.25).timeout
	game.testing_capture_bearing()
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var last_bearing = snapshot.get("last_bearing", {})
	return {
		"name": "bearing_capture",
		"pass": int(snapshot.get("bearings_count", 0)) >= 1 and String(last_bearing.get("broadcast_id", "")) == TARGET_ID,
		"warning": false,
		"details": {
			"bearings_count": snapshot.get("bearings_count", 0),
			"last_bearing": last_bearing,
			"training_step": snapshot.get("training_step", {})
		}
	}


func _run_map_board_fix_case() -> Dictionary:
	game.testing_reset_hunt()
	game.testing_dismiss_welcome_modal()
	var target = game.testing_find_broadcast(TARGET_ID)
	var pos_a: Vector2 = target["position"] + Vector2(-170, -30)
	var pos_b: Vector2 = target["position"] + Vector2(120, 150)
	game.testing_set_player_position(pos_a)
	game.testing_set_aim_direction(target["position"] - pos_a)
	game.testing_set_df_frequency(target["frequency"])
	await _wait_seconds(0.2).timeout
	game.testing_capture_bearing()
	game.testing_set_player_position(pos_b)
	game.testing_set_aim_direction(target["position"] - pos_b)
	await _wait_seconds(0.2).timeout
	game.testing_capture_bearing()
	game.testing_set_fix_position(target["position"] + Vector2(18, -14))
	await _wait_seconds(0.05).timeout
	game.testing_submit_fix()
	await _wait_seconds(0.05).timeout
	var snapshot = game.testing_snapshot()
	var result_text := String(snapshot.get("result_text", ""))
	return {
		"name": "map_board_fix_submission",
		"pass": result_text.contains("Submitted.") and bool(snapshot.get("map_board_summary", {}).get("has_fix", false)),
		"warning": false,
		"details": {
			"result_text": result_text,
			"map_board_summary": snapshot.get("map_board_summary", {})
		}
	}


func _run_df_audio_case() -> Dictionary:
	game.testing_reset_hunt()
	game.testing_dismiss_welcome_modal()
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position: Vector2 = target["position"] + Vector2(-165, 10)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	await _wait_seconds(0.35).timeout
	var snapshot = game.testing_snapshot()
	var receiver = snapshot.get("receiver_profile", {})
	var df_volume_db := float(snapshot.get("df_voice_volume_db", -80.0))
	return {
		"name": "df_audio_audible",
		"pass": String(receiver.get("broadcast_id", "")) == TARGET_ID and df_volume_db > -18.0,
		"warning": false,
		"details": {
			"receiver_profile": receiver,
			"df_voice_volume_db": df_volume_db,
			"df_stream_paused": snapshot.get("df_stream_paused", true)
		}
	}


func _compare_to_previous(current_report: Dictionary, previous: Variant) -> Array:
	var changes: Array = []
	if previous == null or typeof(previous) != TYPE_DICTIONARY:
		return changes
	var previous_cases := {}
	for case_result in previous.get("cases", []):
		previous_cases[case_result.get("name", "")] = case_result
	for case_result in current_report.get("cases", []):
		var case_name: String = case_result.get("name", "")
		if not previous_cases.has(case_name):
			continue
		var previous_pass := bool(previous_cases[case_name].get("pass", false))
		var current_pass := bool(case_result.get("pass", false))
		if previous_pass != current_pass:
			changes.append({
				"name": case_name,
				"previous_pass": previous_pass,
				"current_pass": current_pass
			})
	return changes


func _write_reports(report: Dictionary) -> void:
	var previous_file := FileAccess.open(PREVIOUS_JSON_PATH, FileAccess.WRITE)
	if previous_file != null and previous_report != null:
		previous_file.store_string(JSON.stringify(previous_report, "\t"))
	elif previous_file != null:
		previous_file.store_string(JSON.stringify(report, "\t"))

	var latest_file := FileAccess.open(LATEST_JSON_PATH, FileAccess.WRITE)
	if latest_file != null:
		latest_file.store_string(JSON.stringify(report, "\t"))

	var markdown_lines := [
		"# Testing Agent Report",
		"",
		"- Cases: %d" % int(report.get("summary", {}).get("case_count", 0)),
		"- Passed: %d" % int(report.get("summary", {}).get("pass_count", 0)),
		"- Failed: %d" % int(report.get("summary", {}).get("failed_count", 0)),
		"- Warnings: %d" % int(report.get("summary", {}).get("warning_count", 0)),
		""
	]
	for case_result in report.get("cases", []):
		markdown_lines.append("## %s" % case_result.get("name", "unnamed"))
		markdown_lines.append("")
		markdown_lines.append("- Pass: %s" % str(case_result.get("pass", false)))
		if case_result.has("details"):
			markdown_lines.append("```json")
			markdown_lines.append(JSON.stringify(case_result.get("details", {}), "\t"))
			markdown_lines.append("```")
		markdown_lines.append("")
	var markdown_file := FileAccess.open(LATEST_MD_PATH, FileAccess.WRITE)
	if markdown_file != null:
		markdown_file.store_string("\n".join(markdown_lines))


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed != null else null


func _wait_seconds(seconds: float) -> SceneTreeTimer:
	return create_timer(seconds)
