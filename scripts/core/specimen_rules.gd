class_name SpecimenRules
extends RefCounted
## Pure specimen-acceptance logic for the laboratory receiving floor.
##
## Generation draws a test, the tube received, an optional defect, the fill fraction,
## and a label/requisition pair. The station renders and grades against these values.

const TUBES := {
	"lavender": {"name": "Lavender top", "additive": "K2EDTA", "color": "#9B7FD1"},
	"light_blue": {"name": "Light blue top", "additive": "3.2% sodium citrate", "color": "#6FB7E9"},
	"gold": {"name": "Gold top (SST)", "additive": "clot activator and gel", "color": "#E2B33C"},
	"green": {"name": "Green top", "additive": "lithium heparin", "color": "#3FAE5A"},
	"gray": {"name": "Gray top", "additive": "sodium fluoride/potassium oxalate", "color": "#8A8F99"},
}

const TESTS := {
	"CBC": "lavender",
	"Reticulocyte count": "lavender",
	"ESR (Westergren)": "lavender",
	"Hemoglobin electrophoresis": "lavender",
	"PT/INR": "light_blue",
	"aPTT": "light_blue",
	"Fibrinogen": "light_blue",
	"D-dimer": "light_blue",
}

const NAMES := ["Ana Reyes", "Ben Carter", "Chen Wei", "Dana Okafor", "Eli Novak", "Fatima Khan", "Gus Ortega", "Hana Sato"]

const ACTIONS := ["accept", "reject_wrong_tube", "reject_clotted", "reject_underfilled", "reject_label_mismatch", "reject_hemolyzed"]
const ACTION_LABELS := ["Accept", "Reject: wrong tube", "Reject: clotted", "Reject: underfilled (<90%)", "Reject: label mismatch", "Reject: hemolyzed plasma"]

const ORDER_OF_DRAW := ["culture", "light_blue", "gold", "green", "lavender", "gray"]
const ORDER_LABELS := {
	"culture": "Blood culture bottles",
	"light_blue": "Light blue (citrate)",
	"gold": "Gold/red (serum)",
	"green": "Green (heparin)",
	"lavender": "Lavender (EDTA)",
	"gray": "Gray (fluoride)",
}

const BATCH_HEADER := "Training lab protocol: EDTA for listed hematology tests; 3.2% citrate for listed coagulation tests. Real test directories and rejection policies may differ."

const DEFECTS := ["wrong_tube", "clotted", "underfilled", "label_mismatch", "hemolyzed"]
const CLOTTED_EDTA_TEXT := "Clots trap cells and can distort counts in an anticoagulated EDTA sample. Reject and recollect."
const CLOTTED_CITRATE_TEXT := "Clotting consumes coagulation factors. Reject the clotted anticoagulated specimen and recollect."
const UNDERFILLED_TEXT := "This lab rejects citrate tubes below 90% of nominal draw volume. Filling to the mark gives the intended 9:1 blood-to-anticoagulant ratio; excess citrate from underfilling may falsely prolong clotting times. Reject and recollect."
const LABEL_MISMATCH_TEXT := "Name and date of birth must match the requisition. Hold this mismatched routine specimen and follow the identification/recollection policy; do not guess or relabel it."
const HEMOLYZED_TEXT := "Post-processing plasma inspection shows hemolysis. This simulated coagulation lab rejects it because hemolysis may interfere with the assay. Follow assay-specific rejection policy and recollect."


static func generate(rng: RandomNumberGenerator) -> Dictionary:
	var defect: String = _draw_defect(rng)
	var test: String = _draw_test(rng, defect)
	var required: String = TESTS[test]
	var tube: String = required
	if defect == "wrong_tube":
		tube = _other_tube(required, rng)
	var fill: float = rng.randf_range(0.55, 0.8) if defect == "underfilled" else rng.randf_range(0.95, 1.0)
	var name: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var dob: String = _dob(rng)
	var label_name: String = name
	var label_dob: String = dob
	if defect == "label_mismatch":
		if rng.randi_range(0, 1) == 0:
			label_name = _other_name(name, rng)
		else:
			label_dob = _shift_dob_day(dob, rng)
	return {
		"test": test,
		"required": required,
		"tube": tube,
		"defect": defect,
		"fill": fill,
		"label": {"name": label_name, "dob": label_dob},
		"requisition": {"name": name, "dob": dob},
	}


static func correct_action(s: Dictionary) -> String:
	var defect: String = String(s["defect"])
	if defect == "none":
		return "accept"
	return "reject_" + defect


static func explanation(s: Dictionary) -> String:
	var test: String = String(s["test"])
	var tube: String = String(s["tube"])
	var required: String = String(s["required"])
	var tube_name: String = String(TUBES[tube]["name"])
	var tube_additive: String = String(TUBES[tube]["additive"])
	var required_name: String = String(TUBES[required]["name"])
	var required_additive: String = String(TUBES[required]["additive"])
	match String(s["defect"]):
		"none":
			return "%s uses a %s (%s) under this simulated lab's protocol. Identity, fill, and inspection checks pass. Accept." % [test, tube_name, tube_additive]
		"wrong_tube":
			return "%s uses a %s (%s) under this simulated lab's protocol, but this is a %s. Reject and recollect." % [test, required_name, required_additive, tube_name]
		"clotted":
			if tube == "light_blue":
				return CLOTTED_CITRATE_TEXT
			return CLOTTED_EDTA_TEXT
		"underfilled":
			return UNDERFILLED_TEXT
		"label_mismatch":
			return LABEL_MISMATCH_TEXT
		"hemolyzed":
			return HEMOLYZED_TEXT
	return ""


static func order_step_ok(next_index_expected: int, tapped: String) -> bool:
	if next_index_expected < 0 or next_index_expected >= ORDER_OF_DRAW.size():
		return false
	return ORDER_OF_DRAW[next_index_expected] == tapped


static func _draw_defect(rng: RandomNumberGenerator) -> String:
	var r: float = rng.randf()
	var acc: float = 0.35
	if r < acc:
		return "none"
	for defect: String in DEFECTS:
		acc += 0.13
		if r < acc:
			return defect
	return DEFECTS[DEFECTS.size() - 1]


static func _draw_test(rng: RandomNumberGenerator, defect: String) -> String:
	var keys: Array = TESTS.keys()
	keys.sort()
	var pool: Array = keys
	if defect == "underfilled" or defect == "hemolyzed":
		pool = []
		for key: String in keys:
			if TESTS[key] == "light_blue":
				pool.append(key)
	return String(pool[rng.randi_range(0, pool.size() - 1)])


static func _other_tube(required: String, rng: RandomNumberGenerator) -> String:
	var keys: Array = TUBES.keys()
	keys.sort()
	keys.erase(required)
	return String(keys[rng.randi_range(0, keys.size() - 1)])


static func _other_name(name: String, rng: RandomNumberGenerator) -> String:
	var index: int = NAMES.find(name)
	var pick: int = rng.randi_range(0, NAMES.size() - 2)
	if pick >= index:
		pick += 1
	return NAMES[pick]


static func _dob(rng: RandomNumberGenerator) -> String:
	return "%02d/%02d/%04d" % [rng.randi_range(1, 12), rng.randi_range(1, 19), rng.randi_range(1940, 2004)]


static func _shift_dob_day(dob: String, rng: RandomNumberGenerator) -> String:
	var parts: PackedStringArray = dob.split("/")
	var month: int = int(parts[0])
	var day: int = int(parts[1])
	var year: int = int(parts[2])
	return "%02d/%02d/%04d" % [month, day + rng.randi_range(1, 9), year]
