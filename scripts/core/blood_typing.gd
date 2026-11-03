class_name BloodTyping
extends RefCounted
## Seeded ABO/Rh typing panels and red cell or plasma compatibility questions.

const TYPES := ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
const ANTIBODIES := {"O": "anti-A and anti-B", "A": "anti-B", "B": "anti-A", "AB": "neither anti-A nor anti-B"}


static func abo(type: String) -> String:
	return type.left(type.length() - 1)


static func rh_positive(type: String) -> bool:
	return type.ends_with("+")


static func forward(type: String) -> Dictionary:
	var group: String = abo(type)
	return {
		"Anti-A": "4+" if "A" in group else "0",
		"Anti-B": "4+" if "B" in group else "0",
		"Anti-D": "3+" if rh_positive(type) else "0",
		"Rh control": "0",
	}


static func reverse(type: String) -> Dictionary:
	var group: String = abo(type)
	return {
		"A1 cells": "0" if "A" in group else "4+",
		"B cells": "0" if "B" in group else "4+",
	}


static func red_cell_compatible(patient: String, donor: String) -> bool:
	var patient_abo: String = abo(patient)
	for antigen: String in abo(donor).replace("O", ""):
		if not antigen in patient_abo:
			return false
	return rh_positive(patient) or not rh_positive(donor)


static func generate(rng: RandomNumberGenerator) -> Dictionary:
	var patient: String = TYPES[rng.randi_range(0, TYPES.size() - 1)]
	var fwd: Dictionary = forward(patient)
	var rev: Dictionary = reverse(patient)
	var others: Array[String] = []
	for type: String in TYPES:
		if type != patient:
			others.append(type)
	_shuffle(others, rng)
	var type_choices: Array[String] = [patient]
	type_choices.append_array(others.slice(0, 3))
	var first: Dictionary = _question(
		"Interpret the ABO and Rh type from the forward and reverse grouping.", type_choices,
		"Forward grouping: anti-A %s, anti-B %s, anti-D %s with a negative Rh control; reverse grouping: A1 cells %s, B cells %s. The reverse grouping confirms group %s, and the anti-D reaction makes the patient Rh-%s." % [
			fwd["Anti-A"], fwd["Anti-B"], fwd["Anti-D"], rev["A1 cells"], rev["B cells"], abo(patient), "positive" if rh_positive(patient) else "negative"])
	var second: Dictionary
	if patient == "AB+":
		second = _question("An AB-positive patient needs plasma. Which plasma group is compatible?", ["AB", "O", "A", "B"],
			"AB plasma has neither anti-A nor anti-B, so it is the only plasma compatible with group AB red cells.")
	else:
		var compatible: Array[String] = []
		var incompatible: Array[String] = []
		for donor: String in TYPES:
			if red_cell_compatible(patient, donor):
				compatible.append(donor)
			else:
				incompatible.append(donor)
		var donor_pick: String = compatible[rng.randi_range(0, compatible.size() - 1)]
		_shuffle(incompatible, rng)
		var unit_choices: Array[String] = [donor_pick]
		unit_choices.append_array(incompatible.slice(0, 3))
		var rh_rule: String = "an Rh-positive patient may receive Rh-positive or Rh-negative red cells" if rh_positive(patient) else "an Rh-negative patient must receive Rh-negative red cells"
		second = _question("Which red cell unit is compatible for this patient?", unit_choices,
			"A group %s patient has %s in plasma, so donor red cells must lack the matching antigens, and %s. %s meets both rules." % [abo(patient), ANTIBODIES[abo(patient)], rh_rule, donor_pick])
	return {"patient": patient, "forward": fwd, "reverse": rev, "questions": [first, second] as Array[Dictionary]}


static func _question(stem: String, choices: Array[String], explanation: String) -> Dictionary:
	return {"stem": stem, "choices": choices, "answer": 0, "explanation": explanation, "source": "", "image": null, "topic": "bb"}


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: Variant = items[i]
		items[i] = items[j]
		items[j] = value
