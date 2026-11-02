class_name ContentValidator
extends RefCounted
## Validation is deliberately independent of autoloads and can run on fixtures.

const SUBTOPICS := {
	"phys": ["production", "destruction", "function", "hemoglobin_structure", "iron_metabolism", "bone_marrow", "body_fluids"],
	"rbc": ["microcytic", "hemolytic_hereditary", "hemolytic_acquired", "hypoproliferative", "acute_hemorrhage", "megaloblastic", "nonmegaloblastic_macrocytic", "hemoglobinopathy", "thalassemia", "erythrocytosis"],
	"wbc": ["benign_myeloid", "benign_lymphoid", "acute_myeloid_leukemia", "myelodysplastic", "myeloproliferative", "acute_lymphoid_leukemia", "chronic_lymphoid", "plasma_cell"],
	"plt": ["thrombocytopenia", "thrombocytosis", "qualitative"],
	"lab": ["manual_counts", "automated_counts", "reticulocytes", "spurious_results", "differential_morphology", "hemoglobin", "hematocrit", "indices", "hemolytic_indicators", "special_stains", "esr", "g6pd_heinz", "flow_cytometry", "molecular_cytogenetic", "body_fluid_counts"],
	"hemo": ["coag_pathways", "fibrinolysis", "vascular_platelet_physiology", "factor_deficiency", "fibrinolytic_disorders", "hypercoagulable", "dic", "pt_inr", "aptt", "fibrinogen_ddimer_tt", "mixing_studies", "platelet_function", "thrombophilia_testing", "anti_xa", "specimen_collection"],
	"qc": ["quality_control", "safety", "lab_math", "instrumentation"],
}
const MIN_QUESTIONS := {"phys": 30, "rbc": 60, "wbc": 60, "plt": 25, "lab": 60, "hemo": 50, "qc": 15}
const MIN_TERMS_PER_TOPIC := 10
const DIFF_CLASSES := ["seg", "band", "lymph", "var_lymph", "mono", "eos", "baso", "meta", "myelo", "promyelo", "blast"]
const ART_KINDS := ["rbc", "wbc", "platelet", "field"]
const CATEGORIES := ["rbc", "inclusion", "organism", "wbc", "plt", "stain"]
const REQUIRED_MORPH := [
	"normal_rbc", "microcytic_hypochromic", "macrocyte", "polychromasia", "spherocyte", "target_cell",
	"schistocyte", "sickle_cell", "elliptocyte", "teardrop_cell", "acanthocyte", "echinocyte",
	"stomatocyte", "bite_cell", "rouleaux", "agglutination", "hb_c_crystal", "nrbc",
	"howell_jolly", "basophilic_stippling", "pappenheimer", "heinz_body", "cabot_ring",
	"malaria_falciparum_ring", "babesia", "neutrophil_seg", "neutrophil_band", "lymphocyte",
	"monocyte", "eosinophil", "basophil", "reactive_lymph", "myeloblast", "lymphoblast",
	"promyelocyte", "myelocyte", "metamyelocyte", "plasma_cell", "hypersegmented_neutrophil",
	"auer_rod", "smudge_cell", "hairy_cell", "pelger_huet", "toxic_granulation", "dohle_body",
	"normal_platelet", "giant_platelet", "platelet_clump", "platelet_satellitism", "retic_nmb", "kleihauer_betke",
]
const SOURCE_HOSTS := ["nih.gov", "medlineplus.gov", "cdc.gov", "cancer.gov", "who.int", "fda.gov", "osha.gov", "hematology.org"]
const GENERATED_SOURCE_KEYS := [
	"drill:mcv", "drill:mch", "drill:mchc", "drill:absolute", "drill:corrected_wbc",
	"drill:corrected_retic", "drill:rpi", "drill:hemocytometer", "drill:inr",
	"qc:westgard", "coag:cascade",
	"diff:normal_adult", "diff:allergy_parasite", "diff:bacterial_infection", "diff:viral_reactive",
	"diff:hemolytic_nrbc", "diff:cll", "diff:cml", "diff:aml",
]

static func validate(c: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for error: Variant in c.get("errors", []):
		errors.append(str(error))
	var morph: Dictionary = c.get("morph", {})
	var seen: Dictionary = {}
	var counts: Dictionary = {}
	var sub_counts: Dictionary = {}
	var difficulties: Dictionary = {}
	for topic: String in MIN_QUESTIONS:
		counts[topic] = 0
		difficulties[topic] = {1: 0, 2: 0, 3: 0}
		for subtopic: String in SUBTOPICS[topic]:
			sub_counts[topic + "/" + subtopic] = 0
	for value: Variant in c.get("questions", []):
		if not value is Dictionary:
			errors.append("data/questions [unknown]: question must be an object")
			continue
		var q: Dictionary = value
		var topic: String = str(q.get("topic", ""))
		var where: String = "data/questions/%s.json [%s]" % [topic, q.get("id", "unknown")]
		_register_id(q, where, seen, errors)
		_validate_topic(q, where, errors)
		_validate_question(q, where, morph, errors)
		if q.get("kind", "") not in ["theoretical", "procedural"]:
			errors.append(where + ": kind must be theoretical or procedural")
		var id_pattern := RegEx.new()
		id_pattern.compile("^" + topic + "-[0-9]{4}$")
		if id_pattern.search(str(q.get("id", ""))) == null:
			errors.append(where + ": id must use <topic>-NNNN format")
		if counts.has(topic):
			counts[topic] += 1
			var difficulty: Variant = q.get("difficulty", 0)
			if _integer_in(difficulty, 1, 3):
				difficulties[topic][int(difficulty)] += 1
		var subkey: String = topic + "/" + str(q.get("subtopic", ""))
		if sub_counts.has(subkey):
			sub_counts[subkey] += 1
	for topic: String in counts:
		var where: String = "data/questions/%s.json [bank]" % topic
		if counts[topic] < MIN_QUESTIONS[topic]:
			errors.append("%s: requires at least %d questions (got %d)" % [where, MIN_QUESTIONS[topic], counts[topic]])
		if counts[topic] > 0:
			for difficulty: int in [1, 2, 3]:
				var share: float = float(difficulties[topic][difficulty]) / float(counts[topic])
				var minimum: float = {1: 0.25, 2: 0.35, 3: 0.15}[difficulty]
				if share + 0.000001 < minimum:
					errors.append("%s: difficulty %d share must be at least %.0f%%" % [where, difficulty, minimum * 100.0])
	for key: String in sub_counts:
		if sub_counts[key] < 2:
			errors.append("data/questions/%s.json [%s]: subtopic requires at least 2 questions" % [key.get_slice("/", 0), key.get_slice("/", 1)])
	_validate_morph(morph, errors)
	_validate_photos(c.get("photos", []), morph, errors)
	_validate_cases(c.get("cbc_cases", []), "cbc", morph, seen, errors)
	_validate_cases(c.get("coag_cases", []), "coag", morph, seen, errors)
	_validate_profiles(c.get("diff_profiles", []), errors)
	_validate_glossary(c.get("glossary", []), errors)
	_validate_sources(c, errors)
	return errors

static func _integer_in(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= low and float(value) <= high

static func _text(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func _register_id(item: Dictionary, where: String, seen: Dictionary, errors: Array[String]) -> void:
	var id: String = str(item.get("id", ""))
	if not _text(item.get("id")):
		errors.append(where + ": missing id")
	elif seen.has(id):
		errors.append(where + ": duplicate id (also " + str(seen[id]) + ")")
	else:
		seen[id] = where

static func _validate_topic(item: Dictionary, where: String, errors: Array[String]) -> void:
	var topic: String = str(item.get("topic", ""))
	if not SUBTOPICS.has(topic):
		errors.append(where + ": unknown topic " + topic)
	elif item.get("subtopic", "") not in SUBTOPICS[topic]:
		errors.append(where + ": unknown subtopic " + str(item.get("subtopic", "")))
	if not _integer_in(item.get("difficulty"), 1, 3):
		errors.append(where + ": difficulty must be 1..3")

static func _validate_question(q: Dictionary, where: String, morph: Dictionary, errors: Array[String]) -> void:
	if not _text(q.get("stem")):
		errors.append(where + ": stem must be non-empty")
	var choices: Variant = q.get("choices")
	if not choices is Array or choices.size() != 4:
		errors.append(where + ": choices must contain exactly 4 entries")
	else:
		var distinct: Dictionary = {}
		for choice: Variant in choices:
			if not _text(choice):
				errors.append(where + ": choices must be non-empty strings")
			else:
				var normalized: String = choice.strip_edges().to_lower()
				if distinct.has(normalized):
					errors.append(where + ": choices must be distinct")
				distinct[normalized] = true
	if not _integer_in(q.get("answer"), 0, 3):
		errors.append(where + ": answer must be 0..3")
	if not _text(q.get("explanation")):
		errors.append(where + ": explanation must be non-empty")
	if q.get("image") != null and not morph.has(q["image"]):
		errors.append(where + ": unknown image morphology " + str(q["image"]))

static func _validate_morph(morph: Dictionary, errors: Array[String]) -> void:
	for required_id: String in REQUIRED_MORPH:
		if not morph.has(required_id):
			errors.append("data/morphology.json [%s]: required entity is missing" % required_id)
	for id: String in morph:
		var where: String = "data/morphology.json [%s]" % id
		if not morph[id] is Dictionary:
			errors.append(where + ": entity must be an object")
			continue
		var entity: Dictionary = morph[id]
		for field: String in ["name", "features"]:
			if not _text(entity.get(field)):
				errors.append(where + ": " + field + " must be non-empty")
		if entity.get("category", "") not in CATEGORIES:
			errors.append(where + ": invalid category")
		var associations: Variant = entity.get("associations", [])
		if not associations is Array or associations.size() < 2:
			errors.append(where + ": requires at least 2 associations")
		else:
			for association: Variant in associations:
				if not _text(association):
					errors.append(where + ": associations must be non-empty strings")
		var confusers: Variant = entity.get("confusers", [])
		if not confusers is Array or confusers.size() < 3:
			errors.append(where + ": requires at least 3 confusers")
		else:
			var distinct: Dictionary = {}
			for confuser: Variant in confusers:
				if confuser == id or not morph.has(confuser):
					errors.append(where + ": unknown or self confuser " + str(confuser))
				if distinct.has(confuser):
					errors.append(where + ": confusers must be distinct")
				distinct[confuser] = true
		var art: Variant = entity.get("art", {})
		if not art is Dictionary or art.get("kind", "") not in ART_KINDS:
			errors.append(where + ": art.kind must be rbc, wbc, platelet or field")

static func _validate_photos(photos: Array, morph: Dictionary, errors: Array[String]) -> void:
	var seen: Dictionary = {}
	for photo: Variant in photos:
		if not photo is Dictionary:
			errors.append("data/photos.json [unknown]: photo must be an object")
			continue
		var where: String = "data/photos.json [%s]" % photo.get("id", "unknown")
		_register_id(photo, where, seen, errors)
		if not morph.has(photo.get("morph", "")):
			errors.append(where + ": unknown morphology " + str(photo.get("morph", "")))
		if not FileAccess.file_exists(str(photo.get("file", ""))):
			errors.append(where + ": photo file does not exist: " + str(photo.get("file", "")))

static func _validate_cases(cases: Array, kind: String, morph: Dictionary, seen: Dictionary, errors: Array[String]) -> void:
	var file: String = "data/cases_%s.json" % kind
	var topic_counts: Dictionary = {"rbc": 0, "wbc": 0, "plt": 0, "lab": 0}
	var minimum: int = 30 if kind == "cbc" else 20
	if cases.size() < minimum:
		errors.append("%s [bank]: requires at least %d cases" % [file, minimum])
	for value: Variant in cases:
		if not value is Dictionary:
			errors.append(file + " [unknown]: case must be an object")
			continue
		var case_data: Dictionary = value
		var where: String = "%s [%s]" % [file, case_data.get("id", "unknown")]
		_register_id(case_data, where, seen, errors)
		_validate_topic(case_data, where, errors)
		var topic: String = str(case_data.get("topic", ""))
		if kind == "cbc":
			if topic_counts.has(topic):
				topic_counts[topic] += 1
			else:
				errors.append(where + ": CBC topic must be rbc, wbc, plt or lab")
		elif topic != "hemo":
			errors.append(where + ": coagulation topic must be hemo")
		if not _integer_in(case_data.get("age"), 18, 2147483647):
			errors.append(where + ": patient age must be adult (18 or older)")
		if case_data.get("sex", "") not in ["M", "F"]:
			errors.append(where + ": sex must be M or F")
		if not _text(case_data.get("vignette")):
			errors.append(where + ": vignette must be non-empty")
		var steps: Variant = case_data.get("steps", [])
		if not steps is Array or steps.size() < 2 or steps.size() > 4:
			errors.append(where + ": requires 2..4 steps")
		else:
			for index: int in range(steps.size()):
				if steps[index] is Dictionary:
					_validate_question(steps[index], where + " step %d" % (index + 1), morph, errors)
				else:
					errors.append(where + ": each step must be an object")
		if kind == "cbc":
			_validate_cbc(case_data, where, morph, errors)
		else:
			_validate_coag(case_data, where, errors)
	if kind == "cbc":
		for topic: String in ["rbc", "wbc", "plt"]:
			var needed: int = {"rbc": 14, "wbc": 12, "plt": 4}[topic]
			if topic_counts[topic] < needed:
				errors.append("%s [bank]: requires at least %d %s cases" % [file, needed, topic])

static func _validate_cbc(case_data: Dictionary, where: String, morph: Dictionary, errors: Array[String]) -> void:
	var cbc: Variant = case_data.get("cbc", {})
	if not cbc is Dictionary:
		errors.append(where + ": cbc must be an object")
		return
	var numeric: bool = true
	for key: String in ["WBC", "RBC", "HGB", "HCT", "MCV", "MCH", "MCHC", "RDW", "PLT"]:
		var value: Variant = cbc.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0:
			errors.append(where + ": cbc." + key + " must be a nonnegative number")
			numeric = false
	if numeric and not case_data.get("spurious", false):
		var rbc: float = cbc["RBC"]
		var hct: float = cbc["HCT"]
		var hgb: float = cbc["HGB"]
		if rbc <= 0 or hct <= 0:
			errors.append(where + ": RBC and HCT must be positive for index consistency")
		else:
			if abs(float(cbc["MCV"]) - hct * 10.0 / rbc) > 1.0 + 0.000001:
				errors.append(where + ": inconsistent MCV (expected HCT*10/RBC)")
			if abs(float(cbc["MCH"]) - hgb * 10.0 / rbc) > 0.5 + 0.000001:
				errors.append(where + ": inconsistent MCH (expected HGB*10/RBC)")
			if abs(float(cbc["MCHC"]) - hgb * 100.0 / hct) > 0.5 + 0.000001:
				errors.append(where + ": inconsistent MCHC (expected HGB*100/HCT)")
	var smear: Variant = case_data.get("smear", [])
	if not smear is Array:
		errors.append(where + ": smear must be an array")
	else:
		for id: Variant in smear:
			if not morph.has(id):
				errors.append(where + ": unknown smear morphology " + str(id))

static func _validate_coag(case_data: Dictionary, where: String, errors: Array[String]) -> void:
	var results: Variant = case_data.get("results", {})
	if not results is Dictionary:
		errors.append(where + ": results must be an object")
		return
	if (results.get("PT") == null) != (results.get("INR") == null):
		errors.append(where + ": INR must be non-null if and only if PT is non-null")
	for key: String in results:
		var value: Variant = results[key]
		if key.begins_with("MIX_"):
			if value != null and value not in ["corrected", "not_corrected"]:
				errors.append(where + ": " + key + " must be null, corrected or not_corrected")
		elif value != null and (not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0):
			errors.append(where + ": " + key + " must be null or a nonnegative number")

static func _validate_profiles(profiles: Array, errors: Array[String]) -> void:
	var seen: Dictionary = {}
	for profile: Variant in profiles:
		if not profile is Dictionary:
			errors.append("data/diff_profiles.json [unknown]: profile must be an object")
			continue
		var where: String = "data/diff_profiles.json [%s]" % profile.get("id", "unknown")
		_register_id(profile, where, seen, errors)
		var pct: Variant = profile.get("pct", {})
		if not pct is Dictionary:
			errors.append(where + ": pct must be an object")
			continue
		var total: float = 0.0
		for key: String in pct:
			if key not in DIFF_CLASSES:
				errors.append(where + ": unknown differential class " + key)
			var value: Variant = pct[key]
			if not _integer_in(value, 0, 100):
				errors.append(where + ": pct values must be integers from 0..100")
			else:
				total += float(value)
		if total != 100.0:
			errors.append(where + ": pct must sum to exactly 100")

static func _validate_glossary(glossary: Array, errors: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	var seen_terms: Dictionary = {}
	var counts: Dictionary = {}
	for topic: String in MIN_QUESTIONS:
		counts[topic] = 0
	var id_pattern := RegEx.new()
	id_pattern.compile("^[a-z0-9_]+$")
	for value: Variant in glossary:
		if not value is Dictionary:
			errors.append("data/glossary.json [unknown]: term must be an object")
			continue
		var entry: Dictionary = value
		var where: String = "data/glossary.json [%s]" % entry.get("id", "unknown")
		if not _text(entry.get("id")):
			errors.append(where + ": missing id")
			continue
		var id: String = str(entry["id"])
		if id_pattern.search(id) == null:
			errors.append(where + ": id must match ^[a-z0-9_]+$")
		if seen_ids.has(id):
			errors.append(where + ": duplicate id")
		else:
			seen_ids[id] = true
		var topic: String = str(entry.get("topic", ""))
		if not counts.has(topic):
			errors.append(where + ": unknown topic " + topic)
		else:
			counts[topic] += 1
		if not _text(entry.get("term")):
			errors.append(where + ": term must be non-empty")
		else:
			var normalized: String = str(entry["term"]).strip_edges().to_lower()
			if seen_terms.has(normalized):
				errors.append(where + ": duplicate term")
			else:
				seen_terms[normalized] = true
		var definition: Variant = entry.get("definition", "")
		if not definition is String or str(definition).strip_edges().length() < 20 or str(definition).strip_edges().length() > 300:
			errors.append(where + ": definition must be 20–300 characters")

	for topic: String in counts:
		if counts[topic] < MIN_TERMS_PER_TOPIC:
			errors.append("data/glossary.json [bank]: requires at least %d terms for topic %s (got %d)" % [MIN_TERMS_PER_TOPIC, topic, counts[topic]])

static func _validate_sources(c: Dictionary, errors: Array[String]) -> void:
	var sources: Dictionary = c.get("sources", {})
	var generated: Dictionary = c.get("generated_sources", {})
	var id_pattern := RegEx.new()
	id_pattern.compile("^[a-z0-9-]+$")
	for id: String in sources:
		var where: String = "data/sources.json [%s]" % id
		if id_pattern.search(id) == null:
			errors.append(where + ": id must match ^[a-z0-9-]+$")
		if not sources[id] is Dictionary:
			errors.append(where + ": entry must be an object")
			continue
		var entry: Dictionary = sources[id]
		for field: String in ["title", "publisher", "keyword"]:
			if not _text(entry.get(field)):
				errors.append(where + ": " + field + " must be non-empty")
		if not _source_url_allowed(entry.get("url")):
			errors.append(where + ": url must be https on an allow-listed host (" + str(entry.get("url")) + ")")
	var used: Dictionary = {}
	for key: String in GENERATED_SOURCE_KEYS:
		if not generated.has(key):
			errors.append("data/sources.json [generated]: missing key " + key)
	for key: String in generated:
		if key not in GENERATED_SOURCE_KEYS:
			errors.append("data/sources.json [generated]: unexpected key " + key)
		_check_source(generated[key], "data/sources.json [generated] " + key, sources, used, errors)
	for value: Variant in c.get("questions", []):
		if value is Dictionary:
			var where: String = "data/questions/%s.json [%s]" % [value.get("topic", ""), value.get("id", "unknown")]
			_check_source(value.get("source"), where, sources, used, errors)
	for pair: Array in [["cbc", c.get("cbc_cases", [])], ["coag", c.get("coag_cases", [])]]:
		for value: Variant in pair[1]:
			if not value is Dictionary:
				continue
			var where: String = "data/cases_%s.json [%s]" % [pair[0], value.get("id", "unknown")]
			_check_source(value.get("source"), where, sources, used, errors)
			var steps: Variant = value.get("steps", [])
			if steps is Array:
				for index: int in range(steps.size()):
					if steps[index] is Dictionary and steps[index].has("source"):
						_check_source(steps[index]["source"], where + " step %d" % (index + 1), sources, used, errors)
	var morph: Dictionary = c.get("morph", {})
	for id: String in morph:
		if morph[id] is Dictionary:
			_check_source(morph[id].get("source"), "data/morphology.json [%s]" % id, sources, used, errors)
	for value: Variant in c.get("glossary", []):
		if value is Dictionary:
			_check_source(value.get("source"), "data/glossary.json [%s]" % value.get("id", "unknown"), sources, used, errors)
	for id: String in sources:
		if not used.has(id):
			errors.append("data/sources.json [%s]: unused source" % id)

static func _check_source(value: Variant, where: String, sources: Dictionary, used: Dictionary, errors: Array[String]) -> void:
	if not _text(value):
		errors.append(where + ": missing source")
	elif not sources.has(value):
		errors.append(where + ": unknown source " + str(value))
	else:
		used[value] = true

static func _source_url_allowed(url: Variant) -> bool:
	if not url is String or not url.begins_with("https://"):
		return false
	var rest: String = url.substr(8)
	var end: int = rest.length()
	for separator: String in ["/", "?", "#"]:
		var at: int = rest.find(separator)
		if at >= 0:
			end = mini(end, at)
	var host: String = rest.substr(0, end).to_lower()
	if host.is_empty() or host.begins_with(".") or ".." in host:
		return false
	for index: int in range(host.length()):
		var code: int = host.unicode_at(index)
		if not ((code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code == 45 or code == 46):
			return false
	for allowed: String in SOURCE_HOSTS:
		if host == allowed or host.ends_with("." + allowed):
			return true
	return false
