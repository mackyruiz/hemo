extends GutTest


func test_forward_and_reverse_grouping() -> void:
	assert_eq(BloodTyping.forward("A+"), {"Anti-A": "4+", "Anti-B": "0", "Anti-D": "3+", "Rh control": "0"})
	assert_eq(BloodTyping.forward("AB-"), {"Anti-A": "4+", "Anti-B": "4+", "Anti-D": "0", "Rh control": "0"})
	assert_eq(BloodTyping.reverse("O-"), {"A1 cells": "4+", "B cells": "4+"})
	assert_eq(BloodTyping.reverse("AB+"), {"A1 cells": "0", "B cells": "0"})
	assert_eq(BloodTyping.reverse("B+"), {"A1 cells": "4+", "B cells": "0"})


func test_red_cell_compatibility() -> void:
	for patient: String in BloodTyping.TYPES:
		assert_true(BloodTyping.red_cell_compatible(patient, "O-"), patient)
	assert_false(BloodTyping.red_cell_compatible("A-", "A+"))
	assert_false(BloodTyping.red_cell_compatible("A+", "B+"))
	assert_false(BloodTyping.red_cell_compatible("O+", "A-"))
	assert_true(BloodTyping.red_cell_compatible("AB+", "B+"))


func test_generated_second_question_has_one_compatible_unit() -> void:
	for seed_value in range(1, 201):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var panel: Dictionary = BloodTyping.generate(rng)
		var patient: String = panel["patient"]
		var qs: Array[Dictionary] = panel["questions"]
		assert_eq(qs[0]["choices"][0], patient)
		var choices: Array = qs[1]["choices"]
		if patient == "AB+":
			assert_eq(choices, ["AB", "O", "A", "B"])
			continue
		var compatible: Array = []
		for donor: String in choices:
			if BloodTyping.red_cell_compatible(patient, donor):
				compatible.append(donor)
		assert_eq(compatible, [choices[0]], "seed %d patient %s" % [seed_value, patient])
