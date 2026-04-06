extends SceneTree

const REPORT_DIR := "user://testing_reports"
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
	var exit_code := 0
	var error_text := ""
	var load_result = load(MAIN_SCENE_PATH)
	if load_result == null:
		push_error("Unable to load main scene.")
		quit(1)
		return

	game = load_result.instance()
	root.add_child(game)

	yield(_wait_seconds(0.2), "timeout")

	previous_report = _load_previous_report()
	latest_report = {
		"generated_at": OS.get_datetime().duplicate(true),
		"engine_version": Engine.get_version_info(),
		"cases": [],
		"summary": {},
		"comparison_to_previous": []
	}

	var cases = [
		yield(_run_welcome_modal_case(), "completed"),
		yield(_run_reset_randomization_case(), "completed"),
		yield(_run_df_numeric_entry_case(), "completed"),
		yield(_run_df_audio_audible_case(), "completed"),
		yield(_run_df_audio_consistency_case(), "completed"),
		yield(_run_df_audio_restart_case(), "completed"),
		yield(_run_waterfall_visibility_case(), "completed"),
		yield(_run_waterfall_click_tuning_case(), "completed"),
		yield(_run_waterfall_station_energy_case(), "completed"),
		yield(_run_bearing_capture_audio_continuity_case(), "completed"),
		yield(_run_scanner_lock_case(), "completed"),
		yield(_run_fix_submission_case(), "completed"),
		yield(_run_target_audio_continuity_case(false), "completed"),
		yield(_run_target_audio_continuity_case(true), "completed")
	]

	var pass_count := 0
	var warning_count := 0
	for case_result in cases:
		latest_report["cases"].append(case_result)
		if case_result.get("pass", false):
			pass_count += 1
		if case_result.get("warning", false):
			warning_count += 1
		if not case_result.get("pass", false):
			exit_code = 2

	latest_report["summary"] = {
		"case_count": cases.size(),
		"pass_count": pass_count,
		"warning_count": warning_count,
		"failed_count": cases.size() - pass_count
	}
	latest_report["comparison_to_previous"] = _compare_to_previous(latest_report, previous_report)

	if latest_report["summary"]["failed_count"] > 0:
		error_text = "One or more testing-agent cases failed."

	_write_reports(latest_report, previous_report)
	if error_text != "":
		push_error(error_text)
	yield(_wait_seconds(0.1), "timeout")
	quit(exit_code)


func _run_welcome_modal_case() -> Dictionary:
	var before = game.testing_snapshot()
	var initially_visible = bool(before.get("welcome_modal_visible", false))
	game.testing_dismiss_welcome_modal()
	yield(_wait_seconds(0.05), "timeout")
	var after = game.testing_snapshot()
	var dismissed = not bool(after.get("welcome_modal_visible", true))
	return {
		"name": "welcome_modal",
		"pass": initially_visible and dismissed,
		"warning": false,
		"details": {
			"initially_visible": initially_visible,
			"dismissed": dismissed
		}
	}


func _run_reset_randomization_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.15), "timeout")
	var first_layout = game.testing_get_broadcasts()
	game.testing_reset_hunt()
	yield(_wait_seconds(0.15), "timeout")
	var second_layout = game.testing_get_broadcasts()

	var changed_positions := 0
	var changed_target_frequency := false
	for first_broadcast in first_layout:
		for second_broadcast in second_layout:
			if first_broadcast["id"] != second_broadcast["id"]:
				continue
			if first_broadcast["position"].distance_to(second_broadcast["position"]) > 0.1:
				changed_positions += 1
			if first_broadcast["id"] == TARGET_ID and abs(first_broadcast["frequency"] - second_broadcast["frequency"]) > 0.0001:
				changed_target_frequency = true

	return {
		"name": "reset_randomization",
		"pass": changed_positions >= 2 and changed_target_frequency,
		"warning": false,
		"details": {
			"changed_positions": changed_positions,
			"target_frequency_changed": changed_target_frequency
		}
	}


func _run_df_numeric_entry_case() -> Dictionary:
	game.testing_set_df_frequency_text("146.235")
	yield(_wait_seconds(0.05), "timeout")
	var snapshot = game.testing_snapshot()
	var tuned_ok = abs(snapshot["df_frequency"] - 146.235) < 0.0001
	var text_ok = game.df_frequency_input.text == "146.235"
	return {
		"name": "df_numeric_entry",
		"pass": tuned_ok and text_ok,
		"warning": false,
		"details": {
			"df_frequency": snapshot["df_frequency"],
			"input_text": game.df_frequency_input.text
		}
	}


func _run_df_audio_audible_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position = target["position"] + Vector2(-160, 0)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	var snapshot = {}
	var receiver = {}
	var on_target := false
	var stream_ok := false
	var playing := false
	var loud_enough := false
	var voice_ok := false
	for _i in range(12):
		yield(_wait_seconds(0.1), "timeout")
		snapshot = game.testing_snapshot()
		receiver = snapshot["receiver_profile"]
		on_target = String(receiver["broadcast_id"]) == TARGET_ID
		stream_ok = bool(snapshot["df_has_stream"])
		playing = not bool(snapshot["df_stream_paused"])
		loud_enough = float(snapshot["df_voice_volume_db"]) > -18.0
		voice_ok = float(receiver["voice_level"]) > 0.45
		if on_target and stream_ok and playing and loud_enough and voice_ok:
			break
	return {
		"name": "df_audio_audible",
		"pass": on_target and stream_ok and playing and loud_enough and voice_ok,
		"warning": false,
		"details": {
			"broadcast_id": receiver["broadcast_id"],
			"voice_level": receiver["voice_level"],
			"df_voice_volume_db": snapshot["df_voice_volume_db"],
			"df_has_stream": stream_ok,
			"df_stream_paused": snapshot["df_stream_paused"]
		}
	}


func _run_df_audio_consistency_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	var sample_positions = [
		target["position"] + Vector2(-170, -20),
		target["position"] + Vector2(-130, 55),
		target["position"] + Vector2(-90, 115)
	]
	var db_values := []
	var on_target_count := 0
	for sample_position in sample_positions:
		game.testing_set_player_position(sample_position)
		game.testing_set_aim_direction(target["position"] - sample_position)
		game.testing_set_df_frequency(target["frequency"])
		yield(_wait_seconds(0.25), "timeout")
		var snapshot = game.testing_snapshot()
		var receiver = snapshot["receiver_profile"]
		if String(receiver["broadcast_id"]) == TARGET_ID:
			on_target_count += 1
		db_values.append(float(snapshot["df_voice_volume_db"]))
	var min_db = db_values[0]
	var max_db = db_values[0]
	for db_value in db_values:
		min_db = min(min_db, db_value)
		max_db = max(max_db, db_value)
	return {
		"name": "df_audio_consistency",
		"pass": on_target_count == sample_positions.size() and (max_db - min_db) <= 6.0,
		"warning": false,
		"details": {
			"on_target_count": on_target_count,
			"sample_count": db_values.size(),
			"min_db": min_db,
			"max_db": max_db,
			"db_span": max_db - min_db
		}
	}


func _run_df_audio_restart_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position = target["position"] + Vector2(-160, 0)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	yield(_wait_seconds(0.35), "timeout")
	game.df_voice_player.stop()
	var snapshot = {}
	var receiver = {}
	var restarted := false
	for _i in range(12):
		yield(_wait_seconds(0.1), "timeout")
		snapshot = game.testing_snapshot()
		receiver = snapshot["receiver_profile"]
		restarted = not bool(snapshot["df_stream_paused"]) and float(snapshot["df_playback_position"]) > 0.0
		if String(receiver["broadcast_id"]) == TARGET_ID and bool(snapshot["df_has_stream"]) and restarted and float(snapshot["df_voice_volume_db"]) > -18.0:
			break
	return {
		"name": "df_audio_restart",
		"pass": String(receiver["broadcast_id"]) == TARGET_ID and bool(snapshot["df_has_stream"]) and restarted and float(snapshot["df_voice_volume_db"]) > -18.0,
		"warning": false,
		"details": {
			"broadcast_id": receiver["broadcast_id"],
			"df_has_stream": snapshot["df_has_stream"],
			"df_stream_paused": snapshot["df_stream_paused"],
			"df_playback_position": snapshot["df_playback_position"],
			"df_voice_volume_db": snapshot["df_voice_volume_db"]
		}
	}


func _run_waterfall_visibility_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.8), "timeout")
	var snapshot = game.testing_snapshot()
	var waterfall = snapshot.get("waterfall_summary", {})
	var pass_case = waterfall.get("row_count", 0) >= 10 and waterfall.get("bright_bins", 0) > 0 and waterfall.get("has_texture", false)
	return {
		"name": "waterfall_visibility",
		"pass": pass_case,
		"warning": false,
		"details": {
			"row_count": waterfall.get("row_count", 0),
			"bin_count": waterfall.get("bin_count", 0),
			"max_intensity": waterfall.get("max_intensity", 0.0),
			"average_intensity": waterfall.get("average_intensity", 0.0),
			"bright_bins": waterfall.get("bright_bins", 0),
			"has_texture": waterfall.get("has_texture", false)
		}
	}


func _run_waterfall_click_tuning_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.4), "timeout")
	game.testing_tune_df_from_waterfall_ratio(0.625)
	yield(_wait_seconds(0.05), "timeout")
	var snapshot = game.testing_snapshot()
	var expected_frequency = stepify(lerp(144.0, 148.0, 0.625), 0.005)
	return {
		"name": "waterfall_click_tuning",
		"pass": abs(snapshot["df_frequency"] - expected_frequency) < 0.0001,
		"warning": false,
		"details": {
			"df_frequency": snapshot["df_frequency"],
			"expected_frequency": expected_frequency
		}
	}


func _run_waterfall_station_energy_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.8), "timeout")
	var broadcasts = game.testing_get_broadcasts()
	var strong_count := 0
	var average_strength := 0.0
	for broadcast in broadcasts:
		var intensity = game.testing_get_waterfall_intensity_at_frequency(broadcast["frequency"])
		average_strength += intensity
		if intensity >= 0.12:
			strong_count += 1
	if broadcasts.size() > 0:
		average_strength /= float(broadcasts.size())
	return {
		"name": "waterfall_station_energy",
		"pass": strong_count >= broadcasts.size(),
		"warning": false,
		"details": {
			"broadcast_count": broadcasts.size(),
			"strong_count": strong_count,
			"average_station_intensity": average_strength
		}
	}


func _run_bearing_capture_audio_continuity_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position = target["position"] + Vector2(-160, 0)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	yield(_wait_seconds(0.35), "timeout")
	var before = game.testing_snapshot()
	game.testing_capture_bearing()
	yield(_wait_seconds(0.15), "timeout")
	var after = game.testing_snapshot()
	var same_broadcast = String(after["receiver_profile"]["broadcast_id"]) == TARGET_ID
	var still_playing = not bool(after["df_stream_paused"])
	var playback_advanced = float(after["df_playback_position"]) >= float(before["df_playback_position"])
	return {
		"name": "bearing_capture_audio_continuity",
		"pass": same_broadcast and still_playing and playback_advanced,
		"warning": false,
		"details": {
			"before_playback_position": before["df_playback_position"],
			"after_playback_position": after["df_playback_position"],
			"same_broadcast": same_broadcast,
			"df_stream_paused": after["df_stream_paused"]
		}
	}


func _run_scanner_lock_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	game.testing_set_player_position(target["position"] + Vector2(-180, 0))
	game.testing_set_aim_direction(target["position"] - game.player_position)
	game.testing_trigger_scanner()
	var locked := false
	var locked_id := ""
	for _i in range(80):
		yield(_wait_seconds(0.1), "timeout")
		var snapshot = game.testing_snapshot()
		locked_id = snapshot["scanner_profile"]["broadcast_id"]
		if snapshot["scanner_profile"]["state"] == "locked" and locked_id != "":
			locked = true
			break
	return {
		"name": "scanner_lock",
		"pass": locked,
		"warning": false,
		"details": {
			"locked_broadcast_id": locked_id,
			"scanner_frequency": game.testing_snapshot()["scanner_profile"]["frequency"]
		}
	}


func _run_fix_submission_case() -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	var target = game.testing_find_broadcast(TARGET_ID)
	game.testing_set_df_frequency(target["frequency"])

	var first_origin = target["position"] + Vector2(-180, 0)
	var second_origin = target["position"] + Vector2(0, -180)

	game.testing_set_player_position(first_origin)
	game.testing_set_aim_direction(target["position"] - first_origin)
	yield(_wait_seconds(0.25), "timeout")
	game.testing_capture_bearing()

	game.testing_set_player_position(second_origin)
	game.testing_set_aim_direction(target["position"] - second_origin)
	yield(_wait_seconds(0.25), "timeout")
	game.testing_capture_bearing()

	game.testing_set_fix_position(target["position"] + Vector2(12, -8))
	game.testing_submit_fix()
	yield(_wait_seconds(0.1), "timeout")
	var snapshot = game.testing_snapshot()
	return {
		"name": "fix_submission",
		"pass": snapshot["bearings_count"] >= 2 and String(snapshot["result_text"]).find("Submitted.") != -1,
		"warning": false,
		"details": {
			"bearings_count": snapshot["bearings_count"],
			"result_text": snapshot["result_text"]
		}
	}


func _run_target_audio_continuity_case(clean_monitor_enabled: bool) -> Dictionary:
	game.testing_reset_hunt()
	yield(_wait_seconds(0.1), "timeout")
	game.testing_set_clean_monitor(clean_monitor_enabled)
	var target = game.testing_find_broadcast(TARGET_ID)
	var listen_position = target["position"] + Vector2(-160, 0)
	game.testing_set_player_position(listen_position)
	game.testing_set_aim_direction(target["position"] - listen_position)
	game.testing_set_df_frequency(target["frequency"])
	yield(_wait_seconds(0.3), "timeout")

	var sample_count := 0
	var target_id_samples := 0
	var low_voice_samples := 0
	var playback_resets := 0
	var playback_position_previous := -1.0
	var min_voice_level := 1.0
	var max_noise_level := 0.0
	var dropped_off_target := 0

	for _i in range(120):
		yield(_wait_seconds(0.1), "timeout")
		var snapshot = game.testing_snapshot()
		var receiver = snapshot["receiver_profile"]
		var voice_level = float(receiver["voice_level"])
		var noise_level = float(receiver["noise_level"])
		var broadcast_id = String(receiver["broadcast_id"])
		var playback_position = float(snapshot["df_playback_position"])

		sample_count += 1
		min_voice_level = min(min_voice_level, voice_level)
		max_noise_level = max(max_noise_level, noise_level)
		if broadcast_id == TARGET_ID:
			target_id_samples += 1
		else:
			dropped_off_target += 1

		var low_voice_threshold = 0.85 if clean_monitor_enabled else 0.75
		if voice_level < low_voice_threshold:
			low_voice_samples += 1

		if playback_position_previous >= 0.0 and playback_position + 0.05 < playback_position_previous:
			playback_resets += 1
		playback_position_previous = playback_position
		if playback_resets > 0 and sample_count >= 20:
			break

	var pass_case = dropped_off_target == 0 and low_voice_samples <= 2
	var warning_case = playback_resets == 0
	return {
		"name": "target_audio_continuity_clean" if clean_monitor_enabled else "target_audio_continuity_receiver",
		"pass": pass_case,
		"warning": warning_case,
		"details": {
			"clean_monitor_enabled": clean_monitor_enabled,
			"sample_count": sample_count,
			"target_id_ratio": float(target_id_samples) / float(max(sample_count, 1)),
			"low_voice_samples": low_voice_samples,
			"playback_resets": playback_resets,
			"min_voice_level": min_voice_level,
			"max_noise_level": max_noise_level,
			"dropped_off_target": dropped_off_target
		},
		"note": "Warning means the observed clip never looped during the sample window, so continuity was only verified by stable playback, not by a full wraparound."
	}


func _compare_to_previous(current_report: Dictionary, old_report) -> Array:
	var comparisons := []
	if old_report == null or typeof(old_report) != TYPE_DICTIONARY:
		return comparisons

	var previous_case_map := {}
	for old_case in old_report.get("cases", []):
		previous_case_map[old_case.get("name", "")] = old_case

	for current_case in current_report.get("cases", []):
		var name = current_case.get("name", "")
		if not previous_case_map.has(name):
			comparisons.append({
				"name": name,
				"change": "new_case"
			})
			continue
		var old_case = previous_case_map[name]
		var change = "unchanged"
		if old_case.get("pass", false) != current_case.get("pass", false):
			change = "pass_state_changed"
		elif to_json(old_case.get("details", {})) != to_json(current_case.get("details", {})):
			change = "metrics_changed"
		comparisons.append({
			"name": name,
			"change": change
		})
	return comparisons


func _load_previous_report():
	var previous_text = _read_text_file(LATEST_JSON_PATH)
	if previous_text == "":
		return null
	var parsed = JSON.parse(previous_text)
	if parsed.error != OK:
		return null
	return parsed.result


func _write_reports(current_report: Dictionary, old_report) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(PROJECT_REPORT_DIR):
		dir.make_dir_recursive(PROJECT_REPORT_DIR)

	if old_report != null:
		_write_text_file(PREVIOUS_JSON_PATH, to_json(old_report))
	elif dir.file_exists(PREVIOUS_JSON_PATH):
		dir.remove(PREVIOUS_JSON_PATH)

	_write_text_file(LATEST_JSON_PATH, to_json(current_report))
	_write_text_file(LATEST_MD_PATH, _build_markdown_report(current_report, old_report))


func _build_markdown_report(current_report: Dictionary, old_report) -> String:
	var lines := []
	lines.append("# Testing Agent Report")
	lines.append("")
	lines.append("Generated: %s" % str(current_report.get("generated_at", {})))
	lines.append("")
	var summary = current_report.get("summary", {})
	lines.append("- Cases: %d" % int(summary.get("case_count", 0)))
	lines.append("- Passed: %d" % int(summary.get("pass_count", 0)))
	lines.append("- Failed: %d" % int(summary.get("failed_count", 0)))
	lines.append("- Warnings: %d" % int(summary.get("warning_count", 0)))
	lines.append("")
	for case_result in current_report.get("cases", []):
		lines.append("## %s" % case_result.get("name", "unknown"))
		lines.append("")
		lines.append("- Pass: %s" % str(case_result.get("pass", false)))
		lines.append("- Warning: %s" % str(case_result.get("warning", false)))
		if case_result.has("note"):
			lines.append("- Note: %s" % String(case_result.get("note", "")))
		for detail_key in case_result.get("details", {}).keys():
			lines.append("- %s: %s" % [detail_key, str(case_result["details"][detail_key])])
		lines.append("")
	lines.append("## Comparison")
	lines.append("")
	if old_report == null:
		lines.append("- No previous report was available for comparison.")
	else:
		for comparison in current_report.get("comparison_to_previous", []):
			lines.append("- %s: %s" % [comparison.get("name", "unknown"), comparison.get("change", "unknown")])
	return "\n".join(lines) + "\n"


func _write_text_file(path: String, contents: String) -> void:
	var file = File.new()
	var err = file.open(path, File.WRITE)
	if err != OK:
		push_error("Unable to write report at %s" % path)
		return
	file.store_string(contents)
	file.close()


func _read_text_file(path: String) -> String:
	var file = File.new()
	if not file.file_exists(path):
		return ""
	var err = file.open(path, File.READ)
	if err != OK:
		return ""
	var contents = file.get_as_text()
	file.close()
	return contents


func _wait_seconds(duration: float) -> SceneTreeTimer:
	return create_timer(duration)
