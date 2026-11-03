extends GutTest


func _fixture() -> Dictionary:
	var questions: Array[Dictionary] = []
	var cbc: Array[Dictionary] = []
	var coag: Array[Dictionary] = []
	for topic: String in ["phys", "rbc", "wbc", "plt", "lab", "hemo", "qc"]:
		for i in 18:
			questions.append({"id": "%s-%04d" % [topic, i], "topic": topic, "difficulty": i % 3 + 1})
			if topic in ["rbc", "wbc", "plt"]:
				cbc.append({"id": "cbc-%s-%02d" % [topic, i], "topic": topic, "difficulty": i % 3 + 1})
	for i in 18:
		coag.append({"id": "coag-%02d" % i, "topic": "hemo", "difficulty": i % 3 + 1})
	var morph: Dictionary = {}
	var photos: Dictionary = {}
	for category: String in ["rbc", "wbc", "plt", "stain"]:
		for i in 12:
			var id: String = "%s_%02d" % [category, i]
			morph[id] = {"name": id, "category": category}
			photos[id] = [{"id": id + "_photo"}]
	return {
		"questions": questions, "morph": morph, "photos_by_morph": photos,
		"cbc_cases": cbc, "coag_cases": coag,
		"diff_profiles": [{"id": "normal", "tier": 1}, {"id": "reactive", "tier": 2}, {"id": "blasts", "tier": 3}],
	}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _assert_unique(tasks: Array[Dictionary]) -> void:
	var ids: Dictionary = {}
	for task: Dictionary in tasks:
		var id: String = ""
		if task.has("item_id"):
			id = task["item_id"]
		elif task.has("case_id"):
			id = task["case_id"]
		elif task.has("morph_id"):
			id = "morph:" + str(task["morph_id"])
		if id != "":
			assert_false(ids.has(id), "No repeated tracked item: " + id)
			ids[id] = true


func test_level_one_has_two_morphology_tasks_and_one_safety_task() -> void:
	for seed_value in range(1, 21):
		var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), {}, 1, _rng(seed_value), 1000)
		assert_eq(tasks.size(), 10)
		var morphology_count: int = 0
		var safety_count: int = 0
		for task: Dictionary in tasks:
			assert_true(task["bench"] in ["knowledge", "morphology", "safety"])
			assert_eq(int(task["tier"]), 1)
			if task["bench"] == "morphology":
				morphology_count += 1
				assert_eq(task["variant"], "identify")
			elif task["bench"] == "safety":
				safety_count += 1
		assert_eq(morphology_count, 2)
		assert_eq(safety_count, 1)
		_assert_unique(tasks)


func test_level_five_caps_bench_slots_and_covers_every_unlocked_bench() -> void:
	var seen: Dictionary = {}
	for seed_value in range(1, 31):
		var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), {}, 5, _rng(seed_value), 1000)
		assert_eq(tasks.size(), 10)
		assert_ne(tasks[0]["bench"], "differential")
		var bench_tasks: int = 0
		for task: Dictionary in tasks:
			seen[task["bench"]] = true
			assert_eq(int(task["tier"]), 2)
			if task["bench"] != "knowledge":
				bench_tasks += 1
		assert_eq(bench_tasks, ShiftComposer.MAX_BENCH_SLOTS)
		_assert_unique(tasks)
	var expected: Array = []
	expected.assign(XpRules.unlocked_benches(5))
	var actual: Array = seen.keys()
	expected.sort()
	actual.sort()
	assert_eq(actual, expected)


func test_oldest_due_item_precedes_other_knowledge_items() -> void:
	var progress: Dictionary = {"items": {
		"phys-0000": {"box": 2, "due": 10, "attempts": 1, "correct": 1},
		"phys-0001": {"box": 2, "due": 20, "attempts": 1, "correct": 1},
	}}
	var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), progress, 1, _rng(4), 1000)
	var selected: Array[String] = []
	for task: Dictionary in tasks:
		if task["bench"] == "knowledge":
			selected.append(task["item_id"])
	assert_eq(selected[0], "phys-0000")
	assert_eq(selected[1], "phys-0001")


func test_unseen_weak_topic_precedes_strong_topic() -> void:
	var progress: Dictionary = {"topics": {}}
	for topic: String in ["phys", "rbc", "wbc", "plt", "lab", "hemo", "qc"]:
		progress["topics"][topic] = [true, true, true, true, true]
	progress["topics"]["wbc"] = [false, false, false, false, false]
	var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), progress, 1, _rng(7), 1000, 5, "practice", "knowledge", 1)
	for task: Dictionary in tasks:
		assert_true(str(task["item_id"]).begins_with("wbc-"))


func test_morphology_selection_ignores_unrelated_category_topic_histories() -> void:
	var content: Dictionary = _fixture()
	var weak_rbc: Dictionary = {"topics": {
		"lab": [true, false, true, false, true],
		"rbc": [false, false, false, false, false],
		"wbc": [true, true, true, true, true],
		"plt": [true, true, true, true, true],
	}}
	var weak_wbc: Dictionary = weak_rbc.duplicate(true)
	weak_wbc["topics"]["rbc"] = [true, true, true, true, true]
	weak_wbc["topics"]["wbc"] = [false, false, false, false, false]
	# Morphology attempts persist under lab, so changing disease-topic mastery
	# must not steer the same seeded morphology shift toward a different category.
	for seed_value in range(1, 21):
		var first: Array[Dictionary] = ShiftComposer.compose(content, weak_rbc, 1, _rng(seed_value), 1000, 10, "practice", "morphology", 1)
		var second: Array[Dictionary] = ShiftComposer.compose(content, weak_wbc, 1, _rng(seed_value), 1000, 10, "practice", "morphology", 1)
		assert_eq(first.size(), 10)
		assert_eq(first, second)


func test_fewer_than_five_attempts_counts_as_unmastered() -> void:
	var progress: Dictionary = {"topics": {}}
	for topic: String in ["phys", "rbc", "wbc", "plt", "lab", "hemo", "qc"]:
		progress["topics"][topic] = [false, false, false, false, false]
	progress["topics"]["phys"] = [true, true, true, true]
	var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), progress, 1, _rng(7), 1000, 1, "practice", "knowledge", 1)
	assert_true(str(tasks[0]["item_id"]).begins_with("phys-"))


func test_practice_ignores_unlocks_and_honors_requested_bench() -> void:
	for bench: String in XpRules.BENCH_UNLOCK:
		var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), {}, 1, _rng(12), 1000, 10, "practice", bench, 3)
		assert_eq(tasks.size(), 10)
		for task: Dictionary in tasks:
			assert_eq(task["bench"], bench)
			assert_eq(int(task["tier"]), 3)
		_assert_unique(tasks)


func test_filtered_practice_and_every_fourth_calculation() -> void:
	var tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), {}, 1, _rng(12), 1000, 10, "practice", "knowledge", 2, "hemo")
	for i in tasks.size():
		if i == 3 or i == 7:
			assert_eq(tasks[i].get("drill", ""), "inr")
		else:
			assert_true(str(tasks[i].get("item_id", "")).begins_with("hemo-"))
	var cbc_tasks: Array[Dictionary] = ShiftComposer.compose(_fixture(), {}, 1, _rng(12), 1000, 10, "practice", "cbc", 2, "wbc")
	for task: Dictionary in cbc_tasks:
		assert_true(str(task["case_id"]).begins_with("cbc-wbc-"))


func test_morphology_uses_only_photographed_findings() -> void:
	var content: Dictionary = _fixture()
	for tier in [2, 3]:
		for seed_value in range(1, 21):
			var tasks: Array[Dictionary] = ShiftComposer.compose(content, {}, 1, _rng(seed_value), 1000, 10, "practice", "morphology", tier)
			assert_eq(tasks.size(), 10)
			for task: Dictionary in tasks:
				if tier == 2:
					assert_eq(task["variant"], "identify")
				else:
					assert_true(task["variant"] in ["identify", "association"])
	content["photos_by_morph"] = {"rbc_03": [{"id": "x"}]}
	for seed_value in range(1, 21):
		var tasks: Array[Dictionary] = ShiftComposer.compose(content, {}, 1, _rng(seed_value), 1000, 10, "practice", "morphology", 2)
		assert_eq(tasks.size(), 1)
		assert_eq(tasks[0]["morph_id"], "rbc_03")
	content["photos_by_morph"] = {}
	for seed_value in range(1, 21):
		assert_eq(ShiftComposer.compose(content, {}, 1, _rng(seed_value), 1000, 10, "practice", "morphology", 2).size(), 0)


func test_nearest_difficulty_falls_back_lower_first() -> void:
	var content: Dictionary = _fixture()
	content["questions"] = [{"id": "phys-0001", "topic": "phys", "difficulty": 1}, {"id": "phys-0003", "topic": "phys", "difficulty": 3}]
	# Find a seed whose first draw samples difficulty 2 at tier 2; a one-slot shuffle consumes no draw.
	var seed_value: int = 1
	while true:
		var probe: RandomNumberGenerator = _rng(seed_value)
		var roll: float = probe.randf()
		if roll >= 0.3 and roll < 0.8:
			break
		seed_value += 1
	var tasks: Array[Dictionary] = ShiftComposer.compose(content, {}, 1, _rng(seed_value), 1000, 1, "practice", "knowledge", 2)
	assert_eq(tasks[0]["item_id"], "phys-0001")


func test_composition_is_seed_deterministic() -> void:
	assert_eq(ShiftComposer.compose(_fixture(), {}, 8, _rng(42), 1000), ShiftComposer.compose(_fixture(), {}, 8, _rng(42), 1000))
