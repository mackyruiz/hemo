extends GutTest


func test_reports_list_every_strip_analyte() -> void:
	for id: String in UaCases.SCENARIO_IDS:
		var lines: Array[String] = UaCases.report_lines(id)
		for analyte: String in UaCases.STRIP_ORDER:
			var found: bool = false
			for line: String in lines:
				if line.begins_with(analyte + ": "):
					found = true
			assert_true(found, "%s %s" % [id, analyte])


func test_key_findings() -> void:
	assert_true(UaCases.SCENARIOS["glomerulonephritis"]["sediment"].has("RBC casts 2–5/lpf"))
	assert_eq(UaCases.strip("hemoglobinuria")["Blood"], "Large")
	assert_true(UaCases.SCENARIOS["hemoglobinuria"]["sediment"].has("0–2 RBC/hpf"))
	assert_eq(UaCases.strip("normal")["Glucose"], "Negative")
	assert_eq(UaCases.strip("normal")["Specific gravity"], "1.015")


func test_questions_have_four_distinct_choices() -> void:
	for id: String in UaCases.SCENARIO_IDS:
		for seed_value in range(1, 11):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var qs: Array[Dictionary] = UaCases.questions(id, rng)
			assert_eq(qs.size(), 2, id)
			assert_eq(qs[0]["choices"][0], UaCases.SCENARIOS[id]["label"], id)
			for q: Dictionary in qs:
				var distinct: Dictionary = {}
				for choice: String in q["choices"]:
					distinct[choice] = true
				assert_eq(distinct.size(), 4, id)
				assert_eq(q["topic"], "ua", id)
