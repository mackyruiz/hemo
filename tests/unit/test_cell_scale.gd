extends GutTest

func test_ruler_um_boundaries() -> void:
	assert_eq(CellArt.ruler_um(2.6), 5)
	assert_eq(CellArt.ruler_um(7.5), 10)
	assert_eq(CellArt.ruler_um(9.0), 10)
	assert_eq(CellArt.ruler_um(9.5), 15)
	assert_eq(CellArt.ruler_um(13.5), 15)

func test_art_sizes_match_features_ranges() -> void:
	var content: Dictionary = ContentLoader.load_all()
	assert_eq(content["errors"], [])
	var pattern: RegEx = RegEx.new()
	pattern.compile("(\\d+(?:\\.\\d+)?)\\s*[\u2013-]\\s*(\\d+(?:\\.\\d+)?)\\s*\u00b5m")
	var mismatches: Array[String] = []
	for key: String in content["morph"]:
		var entity: Dictionary = content["morph"][key]
		var art: Dictionary = entity.get("art", {})
		var m: RegExMatch = pattern.search(str(entity.get("features", "")))
		if m == null:
			continue
		var kind: String = str(art.get("kind", "rbc"))
		var default_size: float = 1.6 if kind == "wbc" else (0.35 if kind == "platelet" else (3.2 if kind == "field" else 1.0))
		var size: float = float(art.get("size", default_size))
		var diameter: float = size * 7.5
		var low: float = float(m.get_string(1))
		var high: float = float(m.get_string(2))
		if diameter < low or diameter > high:
			mismatches.append("%s: size %.2f gives %.2f µm, outside %s-%s" % [key, size, diameter, low, high])
	assert_eq(mismatches, [], "\n".join(mismatches))
