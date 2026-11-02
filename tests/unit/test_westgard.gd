extends GutTest


func test_single_run_rejection() -> void:
	var rules: Array[String] = Westgard.evaluate([0.5, -0.3, 3.2], [-0.3, 0.2, 0.1])
	assert_has(rules, "1_3s")
	assert_has(rules, "1_2s")
	assert_true(Westgard.is_reject(rules))
	assert_eq(Westgard.most_severe(rules), "1_3s")


func test_warning_only() -> void:
	var rules: Array[String] = Westgard.evaluate([0.5, -0.3, 2.5], [-0.3, 0.2, -0.1])
	assert_eq(rules, ["1_2s"])
	assert_false(Westgard.is_reject(rules))


func test_two_two_across_runs_and_within_run() -> void:
	assert_has(Westgard.evaluate([0.0, 2.1, 2.3], [0.0, -0.2, 0.1]), "2_2s")
	assert_has(Westgard.evaluate([0.0, 2.2], [0.0, 2.4]), "2_2s")
	assert_has(Westgard.evaluate([0.0, -2.2], [0.0, -2.4]), "2_2s")
	assert_has(Westgard.evaluate([0.0, 0.1], [-2.2, -2.4]), "2_2s")
	assert_does_not_have(Westgard.evaluate([2.2, -2.4], [0.0, 0.1]), "2_2s")


func test_range_four_is_within_run_only() -> void:
	assert_has(Westgard.evaluate([0.0, 2.2], [0.0, -2.1]), "R_4s")
	assert_has(Westgard.evaluate([-2.1], [2.2]), "R_4s")
	assert_does_not_have(Westgard.evaluate([2.2, -2.4], [0.0, 0.1]), "R_4s")


func test_four_one_and_ten_same_side() -> void:
	assert_has(Westgard.evaluate([1.2, 1.5, 1.1, 1.3], [0.0, 0.0, 0.0, 0.0]), "4_1s")
	assert_has(Westgard.evaluate([0.0, 0.0, 0.0, 0.0], [-1.2, -1.5, -1.1, -1.3]), "4_1s")
	var positive: Array[float] = []
	var zero: Array[float] = []
	for i in range(10):
		positive.append(0.4)
		zero.append(0.0)
	assert_has(Westgard.evaluate(positive, zero), "10_x")
	positive[5] = 0.0
	assert_does_not_have(Westgard.evaluate(positive, zero), "10_x")


func test_only_last_run_and_strict_thresholds() -> void:
	assert_eq(Westgard.evaluate([3.5, 0.0], [0.0, 0.0]), [])
	assert_eq(Westgard.evaluate([2.0], [-2.0]), [])
	assert_eq(Westgard.evaluate([3.0], [0.0]), ["1_2s"])
	assert_eq(Westgard.evaluate([1.0, 1.0, 1.0, 1.0], [0.0, 0.0, 0.0, 0.0]), [])
	assert_eq(Westgard.evaluate([], []), [])


func test_error_type_and_severity_priority() -> void:
	assert_eq(Westgard.error_type("R_4s"), "random")
	assert_eq(Westgard.error_type("1_3s"), "random")
	assert_eq(Westgard.error_type("10_x"), "systematic")
	assert_eq(Westgard.error_type("2_2s"), "systematic")
	assert_eq(Westgard.error_type("4_1s"), "systematic")
	assert_eq(Westgard.error_type("1_2s"), "")
	assert_eq(Westgard.most_severe([]), "")
	assert_false(Westgard.is_reject([]))
	var remaining: Array = Westgard.SEVERITY.duplicate()
	for rule: String in Westgard.SEVERITY:
		assert_eq(Westgard.most_severe(remaining), rule)
		remaining.erase(rule)
