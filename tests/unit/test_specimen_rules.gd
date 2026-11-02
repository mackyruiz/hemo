extends GutTest

const CITRATE_TESTS := ["PT/INR", "aPTT", "Fibrinogen", "D-dimer"]


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _valid_dob(dob: String) -> bool:
	var parts := dob.split("/")
	if parts.size() != 3:
		return false
	if parts[0].length() != 2 or parts[1].length() != 2 or parts[2].length() != 4:
		return false
	var month := int(parts[0])
	var day := int(parts[1])
	var year := int(parts[2])
	return month >= 1 and month <= 12 and day >= 1 and day <= 28 and year >= 1940 and year <= 2004


func _explicit(test: String, tube: String, defect: String) -> Dictionary:
	return {
		"test": test,
		"required": String(SpecimenRules.TESTS[test]),
		"tube": tube,
		"defect": defect,
		"fill": 1.0,
		"label": {"name": "Ana Reyes", "dob": "01/02/1980"},
		"requisition": {"name": "Ana Reyes", "dob": "01/02/1980"},
	}


func test_constants_are_contract() -> void:
	assert_eq(SpecimenRules.TUBES.size(), 5)
	assert_eq(String(SpecimenRules.TUBES["lavender"]["additive"]), "K2EDTA")
	assert_eq(String(SpecimenRules.TUBES["light_blue"]["additive"]), "3.2% sodium citrate")
	assert_eq(String(SpecimenRules.TUBES["gold"]["color"]), "#E2B33C")
	assert_eq(SpecimenRules.TESTS.size(), 8)
	assert_eq(String(SpecimenRules.TESTS["CBC"]), "lavender")
	assert_eq(String(SpecimenRules.TESTS["PT/INR"]), "light_blue")
	assert_eq(SpecimenRules.NAMES.size(), 8)
	assert_eq(SpecimenRules.ACTIONS, ["accept", "reject_wrong_tube", "reject_clotted", "reject_underfilled", "reject_label_mismatch", "reject_hemolyzed"])
	assert_eq(SpecimenRules.ACTION_LABELS.size(), 6)
	assert_eq(String(SpecimenRules.ACTION_LABELS[3]), "Reject: underfilled (<90%)")
	assert_eq(SpecimenRules.ORDER_OF_DRAW, ["culture", "light_blue", "gold", "green", "lavender", "gray"])
	for id: String in SpecimenRules.ORDER_OF_DRAW:
		assert_true(SpecimenRules.ORDER_LABELS.has(id), "ORDER_LABELS must label %s" % id)
	assert_eq(String(SpecimenRules.BATCH_HEADER), "Training lab protocol: EDTA for listed hematology tests; 3.2% citrate for listed coagulation tests. Real test directories and rejection policies may differ.")


func test_generation_invariants_across_seeds() -> void:
	for s in range(400):
		var spec: Dictionary = SpecimenRules.generate(_rng(s))
		var defect := String(spec["defect"])
		var test := String(spec["test"])
		var tube := String(spec["tube"])
		var required := String(spec["required"])
		assert_true(SpecimenRules.TESTS.has(test), "generated test must be listed")
		assert_eq(required, String(SpecimenRules.TESTS[test]), "required tube must match the test")
		assert_true(SpecimenRules.TUBES.has(tube), "generated tube must be listed")
		assert_true(SpecimenRules.ACTIONS.has(SpecimenRules.correct_action(spec)))
		assert_true(spec["fill"] > 0.0 and spec["fill"] <= 1.0)
		assert_true(_valid_dob(String(spec["requisition"]["dob"])))
		assert_true(_valid_dob(String(spec["label"]["dob"])))
		if defect == "wrong_tube":
			assert_ne(tube, required, "wrong tube must differ from the required tube")
			assert_ne(String(SpecimenRules.TUBES[tube]["additive"]), String(SpecimenRules.TUBES[required]["additive"]), "wrong tube must change the additive")
		else:
			assert_eq(tube, required, "non-wrong-tube defects keep the required tube")
		if defect == "underfilled" or defect == "hemolyzed":
			assert_true(CITRATE_TESTS.has(test), "%s must use a listed citrate test" % defect)
		if defect == "underfilled":
			assert_true(spec["fill"] >= 0.55 and spec["fill"] <= 0.8, "underfill fraction is in [0.55, 0.8]")
		if defect == "none":
			assert_true(spec["fill"] >= 0.95, "valid specimen is at least 95% filled")
			assert_eq(spec["label"], spec["requisition"], "valid specimen identifiers match")


func test_every_defect_is_generated_and_label_mismatch_only_changes_identifiers() -> void:
	var seen := {}
	for s in range(400):
		var spec: Dictionary = SpecimenRules.generate(_rng(s))
		var defect := String(spec["defect"])
		seen[defect] = true
		if defect == "label_mismatch":
			var label: Dictionary = spec["label"]
			var req: Dictionary = spec["requisition"]
			assert_ne(label, req, "mismatch must break at least one identifier")
			assert_true(_valid_dob(String(label["dob"])), "mismatch keeps a valid label date")
			assert_true(_valid_dob(String(req["dob"])), "mismatch keeps a valid requisition date")
			assert_true(SpecimenRules.NAMES.has(String(label["name"])), "label name stays in NAMES")
			assert_true(SpecimenRules.NAMES.has(String(req["name"])), "requisition name stays in NAMES")
			assert_eq(String(spec["tube"]), String(spec["required"]), "mismatch keeps the required tube")
	for defect: String in SpecimenRules.DEFECTS:
		assert_true(seen.has(defect), "%s must occur across seeds" % defect)
	assert_true(seen.has("none"), "valid specimens must occur across seeds")


func test_explicit_dispositions_are_distinct() -> void:
	var cases := [
		_explicit("CBC", "lavender", "none"),
		_explicit("PT/INR", "light_blue", "underfilled"),
		_explicit("CBC", "lavender", "clotted"),
		_explicit("CBC", "lavender", "label_mismatch"),
		_explicit("PT/INR", "light_blue", "hemolyzed"),
	]
	var actions := []
	for c: Dictionary in cases:
		actions.append(SpecimenRules.correct_action(c))
	assert_eq(actions[0], "accept")
	assert_eq(actions[1], "reject_underfilled")
	assert_eq(actions[2], "reject_clotted")
	assert_eq(actions[3], "reject_label_mismatch")
	assert_eq(actions[4], "reject_hemolyzed")
	var unique := {}
	for a: String in actions:
		unique[a] = true
	assert_eq(unique.size(), actions.size(), "each disposition must be distinct")


func test_explanations_use_exact_texts() -> void:
	assert_eq(SpecimenRules.explanation(_explicit("CBC", "lavender", "none")), "CBC uses a Lavender top (K2EDTA) under this simulated lab's protocol. Identity, fill, and inspection checks pass. Accept.")
	assert_eq(SpecimenRules.explanation(_explicit("CBC", "gold", "wrong_tube")), "CBC uses a Lavender top (K2EDTA) under this simulated lab's protocol, but this is a Gold top (SST). Reject and recollect.")
	assert_eq(SpecimenRules.explanation(_explicit("CBC", "lavender", "clotted")), "Clots trap cells and can distort counts in an anticoagulated EDTA sample. Reject and recollect.")
	assert_eq(SpecimenRules.explanation(_explicit("PT/INR", "light_blue", "clotted")), "Clotting consumes coagulation factors. Reject the clotted anticoagulated specimen and recollect.")
	assert_eq(SpecimenRules.explanation(_explicit("PT/INR", "light_blue", "underfilled")), "This lab rejects citrate tubes below 90% of nominal draw volume. Filling to the mark gives the intended 9:1 blood-to-anticoagulant ratio; excess citrate from underfilling may falsely prolong clotting times. Reject and recollect.")
	assert_eq(SpecimenRules.explanation(_explicit("CBC", "lavender", "label_mismatch")), "Name and date of birth must match the requisition. Hold this mismatched routine specimen and follow the identification/recollection policy; do not guess or relabel it.")
	assert_eq(SpecimenRules.explanation(_explicit("PT/INR", "light_blue", "hemolyzed")), "Post-processing plasma inspection shows hemolysis. This simulated coagulation lab rejects it because hemolysis may interfere with the assay. Follow assay-specific rejection policy and recollect.")
	for c: Dictionary in [_explicit("CBC", "lavender", "none"), _explicit("CBC", "gold", "wrong_tube")]:
		assert_ne(SpecimenRules.explanation(c), "")


func test_draw_order_accepts_next_and_rejects_out_of_order() -> void:
	var order: Array = SpecimenRules.ORDER_OF_DRAW
	for i in range(order.size()):
		assert_true(SpecimenRules.order_step_ok(i, String(order[i])), "step %d accepts its additive" % i)
		assert_false(SpecimenRules.order_step_ok(i, String(order[(i + 1) % order.size()])), "step %d rejects the next additive" % i)
	var last := order.size() - 1
	assert_true(SpecimenRules.order_step_ok(last, "gray"), "near the end the final additive is accepted")
	assert_false(SpecimenRules.order_step_ok(last, "lavender"), "near the end an earlier additive is rejected")
	assert_false(SpecimenRules.order_step_ok(last, "culture"), "culture is out of order at the end")
	assert_false(SpecimenRules.order_step_ok(order.size(), "gray"), "out-of-range step is rejected")
