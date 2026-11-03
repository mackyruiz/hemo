extends GutTest


func test_formula_spot_checks() -> void:
	assert_almost_eq(ChemCalcs.anion_gap(140, 104, 24), 12.0, 1e-9)
	assert_almost_eq(ChemCalcs.osmolality(140, 90, 14), 290.0, 1e-9)
	assert_almost_eq(ChemCalcs.ldl_friedewald(200, 50, 150), 120.0, 1e-9)
	assert_almost_eq(ChemCalcs.non_hdl(200, 50), 150.0, 1e-9)
	assert_almost_eq(CalcDrills.round_to(ChemCalcs.ag_ratio(7.0, 4.0), 1), 1.3, 1e-9)
	assert_almost_eq(ChemCalcs.creatinine_clearance(100, 1.0, 1440), 100.0, 1e-9)
	assert_almost_eq(ChemCalcs.transferrin_saturation(100, 400), 25.0, 1e-9)
	assert_almost_eq(ChemCalcs.indirect_bilirubin(2.0, 0.5), 1.5, 1e-9)


func test_generated_drills_are_positive_and_gradable() -> void:
	for type: String in ChemCalcs.TYPES:
		for seed_value in range(1, 51):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var drill: Dictionary = ChemCalcs.generate(type, rng)
			var context: String = "%s seed %d" % [type, seed_value]
			var answer: float = drill["answer"]
			assert_true(is_finite(answer) and answer > 0.0, context)
			assert_true(CalcDrills.is_correct(drill, CalcDrills.round_to(answer, int(drill["decimals"]))), context)
			assert_eq(drill["topic"], "chem", context)
