extends GutTest


func test_cdc_table_values() -> void:
	assert_eq(HepBPanels.SCENARIOS["acute"]["values"], {"HBsAg": "Positive", "Total anti-HBc": "Positive", "IgM anti-HBc": "Positive", "Anti-HBs": "Negative"})
	assert_eq(HepBPanels.SCENARIOS["susceptible"]["values"]["IgM anti-HBc"], "Not tested")
	assert_eq(HepBPanels.SCENARIOS["immune_vaccine"]["values"]["IgM anti-HBc"], "Not tested")


func test_panels_use_two_distinct_scenarios() -> void:
	for seed_value in range(1, 51):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var qs: Array[Dictionary] = HepBPanels.panels(rng)
		assert_eq(qs.size(), 2)
		assert_ne(qs[0]["choices"][0], qs[1]["choices"][0], "seed %d" % seed_value)
		for q: Dictionary in qs:
			var distinct: Dictionary = {}
			for choice: String in q["choices"]:
				distinct[choice] = true
			assert_eq(distinct.size(), 4)
