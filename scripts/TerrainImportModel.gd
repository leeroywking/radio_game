extends RefCounted
class_name TerrainImportModel

const DEFAULT_PROFILE := {
	"id": "default_hillshade",
	"label": "Default Hillshade",
	"mode": "hillshade_reconstruction",
	"source_path": "res://assets/maps/wa_hillshade.png",
	"grid_size": 128,
	"contrast": 1.18,
	"gamma": 0.82,
	"ridge_weight": 0.72,
	"valley_weight": 0.24,
	"detail_weight": 0.09,
	"spur_weight": 0.07,
	"line_threshold": 0.36,
	"line_influence": 0.22,
	"height_scale": 560.0,
	"height_offset": -180.0
}


func build_heightfield(profile: Dictionary) -> Dictionary:
	var merged := DEFAULT_PROFILE.duplicate(true)
	for key in profile.keys():
		merged[key] = profile[key]
	var size := int(merged.get("grid_size", 128))
	var source := _load_source_image(String(merged.get("source_path", "")), size)
	var heights := PackedFloat32Array()
	heights.resize(size * size)
	var min_height := 999999.0
	var max_height := -999999.0
	for y in range(size):
		for x in range(size):
			var normalized_height := _sample_mode_height(source, x, y, size, merged)
			var world_height: float = float(merged.get("height_offset", -180.0)) + normalized_height * float(merged.get("height_scale", 560.0))
			heights[y * size + x] = world_height
			min_height = min(min_height, world_height)
			max_height = max(max_height, world_height)
	return {
		"profile": merged,
		"source_image": source,
		"heights": heights,
		"size": size,
		"min_height": min_height,
		"max_height": max_height
	}


func _load_source_image(path: String, size: int) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	if source == null or source.is_empty():
		source = Image.create(size, size, false, Image.FORMAT_RGB8)
		source.fill(Color(0.55, 0.55, 0.55))
	else:
		source.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return source


func _sample_mode_height(source: Image, x: int, y: int, size: int, profile: Dictionary) -> float:
	var mode := String(profile.get("mode", "hillshade_reconstruction"))
	if mode == "contour_reconstruction":
		return _sample_contour_height(source, x, y, size, profile)
	return _sample_hillshade_height(source, x, y, size, profile)


func _sample_hillshade_height(source: Image, x: int, y: int, size: int, profile: Dictionary) -> float:
	var luminance := source.get_pixel(x, y).get_luminance()
	var contrast := float(profile.get("contrast", 1.18))
	var gamma := float(profile.get("gamma", 0.82))
	var ridge_weight := float(profile.get("ridge_weight", 0.72))
	var valley_weight := float(profile.get("valley_weight", 0.24))
	var detail_weight := float(profile.get("detail_weight", 0.09))
	var spur_weight := float(profile.get("spur_weight", 0.07))
	var line_influence := float(profile.get("line_influence", 0.22))
	var ridge: float = pow(clampf((luminance - 0.12) * contrast, 0.0, 1.0), gamma) * ridge_weight
	var valley_axis: float = absf(2.0 * (float(y) / float(size - 1)) - 1.0)
	var valley_floor: float = -valley_weight * (1.0 - pow(valley_axis, 1.35))
	var detail: float = detail_weight * sin(float(x) * 0.055) * cos(float(y) * 0.043)
	var spur: float = spur_weight * sin(float(x + y) * 0.024)
	var line_darkness: float = 1.0 - luminance
	var contour_hint: float = maxf(line_darkness - float(profile.get("line_threshold", 0.36)), 0.0) * line_influence
	return clampf(ridge + valley_floor + detail + spur + contour_hint + 0.16, 0.0, 1.0)


func _sample_contour_height(source: Image, x: int, y: int, size: int, profile: Dictionary) -> float:
	var luminance := source.get_pixel(x, y).get_luminance()
	var darkness := 1.0 - luminance
	var line_threshold := float(profile.get("line_threshold", 0.36))
	var line_presence: float = clampf((darkness - line_threshold) / maxf(1.0 - line_threshold, 0.001), 0.0, 1.0)
	var local_gradient: float = _local_gradient(source, x, y, size)
	var broad_rise: float = pow(clampf(luminance * float(profile.get("contrast", 1.0)), 0.0, 1.0), float(profile.get("gamma", 1.0)))
	return clampf(broad_rise * 0.72 + line_presence * 0.22 + local_gradient * 0.12, 0.0, 1.0)


func _local_gradient(source: Image, x: int, y: int, size: int) -> float:
	var x0 := maxi(x - 1, 0)
	var x1 := mini(x + 1, size - 1)
	var y0 := maxi(y - 1, 0)
	var y1 := mini(y + 1, size - 1)
	var left := source.get_pixel(x0, y).get_luminance()
	var right := source.get_pixel(x1, y).get_luminance()
	var down := source.get_pixel(x, y0).get_luminance()
	var up := source.get_pixel(x, y1).get_luminance()
	return clampf(abs(right - left) + abs(up - down), 0.0, 1.0)
