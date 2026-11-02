extends GutTest


func test_all_scenarios_over_fifty_seeds() -> void:
	for scenario: String in QcGenerator.SCENARIOS:
		for seed_value in range(1, 51):
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = seed_value
			var generated: Dictionary = QcGenerator.generate(scenario, rng)
			var levels: Array = generated["levels"]
			var l1: Array[float] = levels[0]["z"]
			var l2: Array[float] = levels[1]["z"]
			var expected: String = "" if scenario == "none" else scenario
			if scenario.begins_with("2_2s_"):
				expected = "2_2s"
			var context: String = "%s seed %d" % [scenario, seed_value]
			assert_eq(generated["expected_rule"], expected, context)
			assert_eq(generated["scenario"], scenario, context)
			assert_eq(Westgard.most_severe(Westgard.evaluate(l1, l2)), expected, context)
			assert_false(String(generated["unit"]).is_empty(), context)
			for level: Dictionary in levels:
				var z: Array[float] = level["z"]
				var values: Array[float] = level["values"]
				var mean_value: float = level["mean"]
				var sd: float = level["sd"]
				assert_eq(z.size(), 20, context)
				assert_eq(values.size(), 20, context)
				for i in range(20):
					assert_almost_eq(values[i], mean_value + z[i] * sd, 0.01, context)
					assert_almost_eq(values[i], roundf(values[i] * 100.0) / 100.0, 1e-9, context)
			# Prefixes before deliberate injection must still be in control.
			var untouched_runs: int = 19
			if scenario == "2_2s_across":
				untouched_runs = 18
			elif scenario == "4_1s":
				untouched_runs = 16
			elif scenario == "10_x":
				untouched_runs = 10
			for length in range(1, untouched_runs + 1):
				assert_eq(Westgard.evaluate(l1.slice(0, length), l2.slice(0, length)), [], context)


func test_injected_rng_is_reproducible() -> void:
	var first: RandomNumberGenerator = RandomNumberGenerator.new()
	var second: RandomNumberGenerator = RandomNumberGenerator.new()
	first.seed = 719
	second.seed = 719
	assert_eq(QcGenerator.generate("R_4s", first), QcGenerator.generate("R_4s", second))
