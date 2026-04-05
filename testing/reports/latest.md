# Testing Agent Report

Generated: {day:5, dst:True, hour:14, minute:9, month:4, second:20, weekday:0, year:2026}

- Cases: 6
- Passed: 6
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
- low_voice_samples: 0
- playback_resets: 0
- min_voice_level: 0.915655
- max_noise_level: 0.004192
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
- scanner_lock: unchanged
- fix_submission: unchanged
- target_audio_continuity_receiver: metrics_changed
- target_audio_continuity_clean: unchanged
