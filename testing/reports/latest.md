# Testing Agent Report

Generated: {day:5, dst:True, hour:14, minute:47, month:4, second:45, weekday:0, year:2026}

- Cases: 10
- Passed: 10
- Failed: 0
- Warnings: 2

## reset_randomization

- Pass: True
- Warning: False
- changed_positions: 4
- target_frequency_changed: True

## df_numeric_entry

- Pass: True
- Warning: False
- df_frequency: 146.235
- input_text: 146.235

## waterfall_visibility

- Pass: True
- Warning: False
- row_count: 10
- bin_count: 72
- max_intensity: 0.61225
- average_intensity: 0.068112
- bright_bins: 30
- has_texture: True

## waterfall_click_tuning

- Pass: True
- Warning: False
- df_frequency: 146.5
- expected_frequency: 146.5

## waterfall_station_energy

- Pass: True
- Warning: False
- broadcast_count: 4
- strong_count: 4
- average_station_intensity: 0.278706

## bearing_capture_audio_continuity

- Pass: True
- Warning: False
- before_playback_position: 0.41483
- after_playback_position: 0.556281
- same_broadcast: True
- df_stream_paused: False

## scanner_lock

- Pass: True
- Warning: False
- locked_broadcast_id: lesson_bravo
- scanner_frequency: 145.41

## fix_submission

- Pass: True
- Warning: False
- bearings_count: 2
- result_text: Submitted. Fix error: 14 px. Excellent fix. Target frequency confirmed.

## target_audio_continuity_receiver

- Pass: True
- Warning: True
- Note: Warning means the observed clip never looped during the sample window, so continuity was only verified by stable playback, not by a full wraparound.
- clean_monitor_enabled: False
- sample_count: 120
- target_id_ratio: 1
- low_voice_samples: 1
- playback_resets: 0
- min_voice_level: 0.678828
- max_noise_level: 0.304007
- dropped_off_target: 0

## target_audio_continuity_clean

- Pass: True
- Warning: True
- Note: Warning means the observed clip never looped during the sample window, so continuity was only verified by stable playback, not by a full wraparound.
- clean_monitor_enabled: True
- sample_count: 120
- target_id_ratio: 1
- low_voice_samples: 0
- playback_resets: 0
- min_voice_level: 0.884444
- max_noise_level: 0
- dropped_off_target: 0

## Comparison

- reset_randomization: unchanged
- df_numeric_entry: unchanged
- waterfall_visibility: metrics_changed
- waterfall_click_tuning: unchanged
- waterfall_station_energy: metrics_changed
- bearing_capture_audio_continuity: metrics_changed
- scanner_lock: unchanged
- fix_submission: unchanged
- target_audio_continuity_receiver: unchanged
- target_audio_continuity_clean: unchanged
