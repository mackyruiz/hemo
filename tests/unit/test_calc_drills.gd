extends GutTest


func test_every_type_over_fifty_seeds() -> void:
	for type: String in CalcDrills.TYPES:
		for seed_value in range(1, 51):
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = seed_value
			var drill: Dictionary = CalcDrills.generate(type, rng)
			var answer: float = drill["answer"]
			var decimals: int = drill["decimals"]
			var inputs: Dictionary = drill["inputs"]
			var context: String = "%s seed %d" % [type, seed_value]
			assert_true(is_finite(answer), context)
			assert_gt(answer, 0.0, context)
			assert_almost_eq(answer, _recompute(type, inputs), 1e-9, context)
			assert_eq(drill["type"], type, context)
			assert_eq(drill["topic"], "hemo" if type == "inr" else "lab", context)
			assert_eq(decimals, 0 if type in ["mcv", "hemocytometer"] else 1, context)
			assert_false(String(drill["unit"]).is_empty(), context)
			assert_false(String(drill["explanation"]).is_empty(), context)
			assert_true(String(drill["stem"]).contains("Round to %d decimal" % decimals), context)
			var rounded: float = CalcDrills.round_to(answer, decimals)
			var unit_value: float = pow(10.0, -decimals)
			assert_true(CalcDrills.is_correct(drill, rounded), context)
			assert_true(CalcDrills.is_correct(drill, rounded + unit_value), context)
			assert_true(CalcDrills.is_correct(drill, rounded - unit_value), context)
			assert_false(CalcDrills.is_correct(drill, rounded + 3.0 * unit_value), context)
			assert_false(CalcDrills.is_correct(drill, rounded - 3.0 * unit_value), context)


func test_rounding() -> void:
	assert_eq(CalcDrills.round_to(32.246, 1), 32.2)
	assert_eq(CalcDrills.round_to(32.246, 2), 32.25)
	assert_eq(CalcDrills.round_to(90.49, 0), 90.0)
	assert_eq(CalcDrills.round_to(90.5, 0), 91.0)


func test_rng_reproducibility() -> void:
	var first: RandomNumberGenerator = RandomNumberGenerator.new()
	var second: RandomNumberGenerator = RandomNumberGenerator.new()
	first.seed = 91
	second.seed = 91
	for type: String in CalcDrills.TYPES:
		assert_eq(CalcDrills.generate(type, first), CalcDrills.generate(type, second))


func _recompute(type: String, inputs: Dictionary) -> float:
	match type:
		"mcv":
			return HemeCalc.mcv(inputs["hct"], inputs["rbc"])
		"mch":
			return HemeCalc.mch(inputs["hgb"], inputs["rbc"])
		"mchc":
			return HemeCalc.mchc(inputs["hgb"], inputs["hct"])
		"absolute":
			return HemeCalc.absolute(inputs["wbc"], inputs["pct"])
		"corrected_wbc":
			return HemeCalc.corrected_wbc(inputs["wbc"], inputs["nrbc_per_100"])
		"corrected_retic":
			return HemeCalc.corrected_retic(inputs["retic_pct"], inputs["hct"], inputs["normal_hct"])
		"rpi":
			return HemeCalc.rpi(inputs["retic_pct"], inputs["hct"])
		"hemocytometer":
			return HemeCalc.hemocytometer(inputs["cells"], inputs["area_mm2"], inputs["dilution"], inputs["depth_mm"])
		"inr":
			return HemeCalc.inr(inputs["pt"], inputs["mnpt"], inputs["isi"])
	fail_test("Unrecognized type in test: " + type)
	return -1.0
