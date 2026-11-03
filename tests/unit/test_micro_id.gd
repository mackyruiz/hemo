extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_stain_and_first_test_answers_follow_group() -> void:
	for id: String in MicroId.ORGANISM_IDS:
		var org: Dictionary = MicroId.organism(id)
		var qs: Array[Dictionary] = MicroId.questions(id, _rng(7))
		assert_eq(qs.size(), 3, id)
		assert_eq(qs[0]["choices"][0], MicroId.GROUP_LABELS[org["group"]], id)
		var expected: String = "Oxidase" if org["group"] == "gnb" else "Catalase"
		assert_eq(qs[1]["choices"][0], expected, id)
		for q: Dictionary in qs:
			var distinct: Dictionary = {}
			for choice: String in q["choices"]:
				distinct[choice] = true
			assert_eq(distinct.size(), 4, id)
			assert_eq(q["answer"], 0, id)
			assert_eq(q["topic"], "micro", id)


func test_identification_distractors_prefer_same_group() -> void:
	for seed_value in range(1, 21):
		var qs: Array[Dictionary] = MicroId.questions("s_saprophyticus", _rng(seed_value))
		var choices: Array = qs[2]["choices"]
		assert_eq(choices[0], "Staphylococcus saprophyticus")
		assert_true(choices.has("Staphylococcus aureus"))
		assert_true(choices.has("Staphylococcus epidermidis"))
	for id: String in MicroId.ORGANISM_IDS:
		var group: String = MicroId.organism(id)["group"]
		var choices: Array = MicroId.questions(id, _rng(3))[2]["choices"]
		var same: int = 0
		for name: String in choices.slice(1):
			for other: Dictionary in MicroId.ORGANISMS:
				if other["name"] == name and other["group"] == group:
					same += 1
		var available: int = -1
		for other: Dictionary in MicroId.ORGANISMS:
			if other["group"] == group:
				available += 1
		assert_eq(same, mini(3, available), id)


func test_same_seed_is_deterministic() -> void:
	for id: String in MicroId.ORGANISM_IDS:
		assert_eq(MicroId.questions(id, _rng(42)), MicroId.questions(id, _rng(42)), id)
