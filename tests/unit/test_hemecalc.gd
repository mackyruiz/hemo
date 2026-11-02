extends GutTest


func test_red_cell_indices() -> void:
	assert_eq(HemeCalc.mcv(45.0, 5.0), 90.0)
	assert_eq(HemeCalc.mch(15.0, 5.0), 30.0)
	assert_almost_eq(HemeCalc.mchc(15.0, 45.0), 33.33, 0.01)


func test_absolute_and_corrected_wbc() -> void:
	assert_eq(HemeCalc.absolute(8.0, 60.0), 4.8)
	assert_eq(HemeCalc.corrected_wbc(10.0, 25.0), 8.0)


func test_reticulocyte_corrections() -> void:
	assert_almost_eq(HemeCalc.corrected_retic(2.0, 30.0), 1.333, 0.001)
	assert_almost_eq(HemeCalc.rpi(2.0, 30.0), 0.889, 0.001)
	assert_eq(HemeCalc.corrected_retic(2.0, 30.0, 40.0), 1.5)


func test_maturation_factor_boundaries() -> void:
	assert_eq(HemeCalc.maturation_factor(40.0), 1.0)
	assert_eq(HemeCalc.maturation_factor(39.9), 1.5)
	assert_eq(HemeCalc.maturation_factor(30.0), 1.5)
	assert_eq(HemeCalc.maturation_factor(29.9), 2.0)
	assert_eq(HemeCalc.maturation_factor(20.0), 2.0)
	assert_eq(HemeCalc.maturation_factor(19.9), 2.5)


func test_inr() -> void:
	assert_eq(HemeCalc.inr(26.0, 13.0, 1.0), 2.0)
	assert_almost_eq(HemeCalc.inr(18.0, 12.0, 1.2), 1.627, 0.001)


func test_manual_count_and_rule_of_three() -> void:
	assert_eq(HemeCalc.hemocytometer(200.0, 4.0, 20.0), 10000.0)
	assert_eq(HemeCalc.hemocytometer(200.0, 4.0, 20.0, 0.2), 5000.0)
	assert_true(HemeCalc.rule_of_three_ok(12.0, 36.0))
	assert_true(HemeCalc.rule_of_three_ok(12.0, 39.0))
	assert_false(HemeCalc.rule_of_three_ok(12.0, 42.0))
	assert_false(HemeCalc.rule_of_three_ok(12.0, 38.0, 1.0))
