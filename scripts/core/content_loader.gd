class_name ContentLoader
extends RefCounted
## Single file-loading path for runtime content and content validation tests.

const TOPICS := ["phys", "rbc", "wbc", "plt", "lab", "hemo", "qc"]

static func load_all() -> Dictionary:
	var errors: Array[String] = []
	var content: Dictionary = {
		"questions": [], "morph": {}, "photos": [], "cbc_cases": [],
		"coag_cases": [], "diff_profiles": [], "ranges": {}, "sources": {}, "generated_sources": {}, "glossary": [], "errors": errors,
	}
	for topic: String in TOPICS:
		var questions: Variant = _load_json("res://data/questions/%s.json" % topic, TYPE_ARRAY, errors)
		if questions is Array:
			content["questions"].append_array(questions)
	var paths: Dictionary = {
		"morph": ["res://data/morphology.json", TYPE_DICTIONARY],
		"photos": ["res://data/photos.json", TYPE_ARRAY],
		"cbc_cases": ["res://data/cases_cbc.json", TYPE_ARRAY],
		"coag_cases": ["res://data/cases_coag.json", TYPE_ARRAY],
		"diff_profiles": ["res://data/diff_profiles.json", TYPE_ARRAY],
		"ranges": ["res://data/reference_ranges.json", TYPE_DICTIONARY],
		"glossary": ["res://data/glossary.json", TYPE_ARRAY],
	}
	for key: String in paths:
		var spec: Array = paths[key]
		var value: Variant = _load_json(spec[0], spec[1], errors)
		if value != null:
			content[key] = value
	var sources_file: Variant = _load_json("res://data/sources.json", TYPE_DICTIONARY, errors)
	if sources_file != null:
		for pair: Array in [["sources", "sources"], ["generated", "generated_sources"]]:
			var section: Variant = sources_file.get(pair[0])
			if section is Dictionary:
				content[pair[1]] = section
			else:
				errors.append("res://data/sources.json: missing '%s' object" % pair[0])
	return content

static func _load_json(path: String, expected_type: int, errors: Array[String]) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("%s: file is missing" % path)
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		errors.append("%s: cannot read file (%s)" % [path, error_string(open_error)])
		return null
	var value: Variant = JSON.parse_string(text)
	if value == null:
		errors.append("%s: invalid JSON or null root" % path)
		return null
	if typeof(value) != expected_type:
		errors.append("%s: expected a JSON %s" % [path, "array" if expected_type == TYPE_ARRAY else "object"])
		return null
	return value
