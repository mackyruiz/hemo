extends Node
## Loaded educational content and indexes shared by the screens and benches.

var questions: Array = []
var questions_by_id: Dictionary = {}
var morph: Dictionary = {}
var photos: Array = []
var photos_by_morph: Dictionary = {}
var cbc_cases: Array = []
var coag_cases: Array = []
var cases_by_id: Dictionary = {}
var diff_profiles: Array = []
var ranges: Dictionary = {}
var sources: Dictionary = {}
var generated_sources: Dictionary = {}
var load_errors: Array[String] = []


func _ready() -> void:
	var loaded: Dictionary = ContentLoader.load_all()
	questions = loaded.get("questions", [])
	morph = loaded.get("morph", {})
	photos = loaded.get("photos", [])
	cbc_cases = loaded.get("cbc_cases", [])
	coag_cases = loaded.get("coag_cases", [])
	diff_profiles = loaded.get("diff_profiles", [])
	ranges = loaded.get("ranges", {})
	sources = loaded.get("sources", {})
	generated_sources = loaded.get("generated_sources", {})
	for message in loaded.get("errors", []):
		load_errors.append(str(message))
		push_error(str(message))
	for question in questions:
		questions_by_id[str(question["id"])] = question
	for photo in photos:
		var morph_id: String = str(photo["morph"])
		if not photos_by_morph.has(morph_id):
			photos_by_morph[morph_id] = []
		photos_by_morph[morph_id].append(photo)
	for case_data in cbc_cases + coag_cases:
		cases_by_id[str(case_data["id"])] = case_data
	if OS.is_debug_build():
		for finding in ContentValidator.validate(loaded):
			push_error(finding)


func flag(key: String, value: float, sex: String) -> String:
	var reference: Dictionary = ranges.get(key, {})
	if reference.has("M") or reference.has("F"):
		reference = reference.get(sex, {})
	if not reference.has("low") or not reference.has("high"):
		return ""
	if value < float(reference["low"]):
		return "L"
	if value > float(reference["high"]):
		return "H"
	return ""


func profile(id: String) -> Dictionary:
	for entry in diff_profiles:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func as_dict() -> Dictionary:
	return {
		"questions": questions,
		"morph": morph,
		"photos_by_morph": photos_by_morph,
		"cbc_cases": cbc_cases,
		"coag_cases": coag_cases,
		"diff_profiles": diff_profiles,
		"ranges": ranges,
	}


func morph_name(id: String) -> String:
	var entity: Dictionary = morph.get(id, {})
	return str(entity.get("name", id))
