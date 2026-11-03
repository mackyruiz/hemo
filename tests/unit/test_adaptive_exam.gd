extends GutTest


func _fixture(with_photos: bool = true) -> Dictionary:
	var questions: Array[Dictionary] = []
	for topic: String in AdaptiveExam.BLUEPRINT:
		for difficulty in range(1, 4):
			for i in 12:
				questions.append({
					"id": "%s-%d-%02d" % [topic, difficulty, i], "topic": topic,
					"difficulty": difficulty, "stem": "A unique fixture question.",
					"choices": ["A", "B", "C", "D"], "answer": 0,
					"explanation": "A is correct.", "image": null,
				})
	var morph: Dictionary = {}
	var photos: Dictionary = {}
	for i in 8:
		var id: String = "cell_%d" % i
		var confusers: Array[String] = []
		for offset in range(1, 4):
			confusers.append("cell_%d" % ((i + offset) % 8))
		morph[id] = {"name": "Cell %d" % i, "category": "wbc", "features": "Recognizable fixture morphology.", "confusers": confusers}
		if with_photos:
			photos[id] = [{"id": id + "_1"}]
	return {"questions": questions, "morph": morph, "photos_by_morph": photos}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_correct_correct_wrong_adapts_difficulty() -> void:
	var exam := AdaptiveExam.new(_fixture(false), _rng(1))
	assert_eq(exam.difficulty, 2)
	assert_eq(int(exam.next_item()["difficulty"]), 2)
	exam.answer(true, 1.0, 0)
	assert_eq(exam.difficulty, 3)
	assert_eq(int(exam.next_item()["difficulty"]), 3)
	exam.answer(true, 1.0, 0)
	assert_eq(exam.difficulty, 3)
	exam.next_item()
	exam.answer(false, 1.0, 1)
	assert_eq(exam.difficulty, 2)


func test_hundred_unique_items_match_blueprint_with_two_photo_items() -> void:
	for seed_value in range(1, 11):
		var content: Dictionary = _fixture()
		var exam := AdaptiveExam.new(content, _rng(seed_value))
		var seen: Dictionary = {}
		var topics: Dictionary = {}
		var photo_count: int = 0
		while not exam.is_done():
			var item: Dictionary = exam.next_item()
			assert_false(item.is_empty())
			if item.is_empty():
				break
			assert_eq(item, exam.next_item(), "The current item is stable until answered")
			var id: String = item["id"]
			assert_false(seen.has(id), "No repeated ids")
			seen[id] = true
			var topic: String = item["topic"]
			topics[topic] = int(topics.get(topic, 0)) + 1
			if id.begins_with("morph:"):
				photo_count += 1
				assert_eq(topic, "lab")
				assert_eq(int(item["difficulty"]), 2)
				assert_eq(item["stem"], "Identify the cell/finding indicated.")
				assert_true(content["photos_by_morph"].has(item["image"]))
				var choices: Array = item["choices"]
				assert_eq(choices.size(), 4)
				var unique: Dictionary = {}
				for choice: String in choices:
					unique[choice] = true
				assert_eq(unique.size(), 4)
				assert_eq(choices[int(item["answer"])], content["morph"][item["image"]]["name"])
			exam.answer(true, 2.0, int(item["answer"]))
		assert_eq(seen.size(), 100)
		assert_eq(topics, AdaptiveExam.BLUEPRINT)
		assert_eq(photo_count, 2)
		assert_eq(exam.count_answered(), 100)
		assert_eq(exam.next_item(), {})
		var results: Dictionary = exam.results()
		assert_eq(int(results["correct"]), 100)
		assert_eq(int(results["total"]), 100)
		assert_eq(float(results["score"]), 1.0)
		assert_eq(float(results["duration_s"]), 200.0)
		for topic: String in AdaptiveExam.BLUEPRINT:
			assert_eq(int(results["by_topic"][topic]["correct"]), int(AdaptiveExam.BLUEPRINT[topic]))
			assert_eq(int(results["by_topic"][topic]["total"]), int(AdaptiveExam.BLUEPRINT[topic]))
		for record: Dictionary in results["items"]:
			assert_true(record.has("item"))
			assert_eq(record["id"], record["item"]["id"])
			assert_eq(int(record["chosen"]), int(record["item"]["answer"]))


func test_no_photos_still_produces_hundred_blueprint_items() -> void:
	var exam := AdaptiveExam.new(_fixture(false), _rng(9))
	while not exam.is_done():
		var item: Dictionary = exam.next_item()
		assert_false(str(item["id"]).begins_with("morph:"))
		exam.answer(false, 1.0)
	assert_eq(exam.count_answered(), 100)
	assert_eq(float(exam.results()["score"]), 0.0)


func test_recent_ids_are_avoided_when_fresh_items_exist() -> void:
	var content: Dictionary = _fixture()
	var recent: Array[String] = []
	for topic: String in AdaptiveExam.BLUEPRINT:
		recent.append("%s-2-00" % topic)
	recent.append("morph:cell_0")
	recent.append("morph:cell_1")
	var exam := AdaptiveExam.new(content, _rng(17), recent)
	while not exam.is_done():
		var item: Dictionary = exam.next_item()
		assert_false(recent.has(str(item["id"])))
		exam.answer(true, 1.0)


func test_recent_items_can_be_used_when_no_fresh_items_remain() -> void:
	var content: Dictionary = _fixture(false)
	var recent: Array[String] = []
	for item: Dictionary in content["questions"]:
		recent.append(item["id"])
	var exam := AdaptiveExam.new(content, _rng(17), recent)
	assert_false(exam.next_item().is_empty())


func test_timeout_counts_presented_and_remaining_items_wrong() -> void:
	var exam := AdaptiveExam.new(_fixture(), _rng(5))
	var first: Dictionary = exam.next_item()
	exam.answer(true, 7.0, int(first["answer"]))
	var presented_id: String = exam.next_item()["id"]
	exam.mark_timeout()
	assert_true(exam.is_done())
	assert_eq(exam.count_answered(), 100)
	var results: Dictionary = exam.results()
	assert_eq(int(results["correct"]), 1)
	assert_eq(int(results["total"]), 100)
	assert_almost_eq(float(results["score"]), 0.01, 0.000001)
	assert_eq(float(results["duration_s"]), float(AdaptiveExam.DURATION_S))
	var records: Array = results["items"]
	assert_eq(records[1]["id"], presented_id)
	for i in range(1, records.size()):
		assert_false(bool(records[i]["correct"]))
		assert_eq(int(records[i]["chosen"]), -1)
	var topic_total: int = 0
	for topic: String in AdaptiveExam.BLUEPRINT:
		assert_eq(int(results["by_topic"][topic]["total"]), int(AdaptiveExam.BLUEPRINT[topic]))
		topic_total += int(results["by_topic"][topic]["total"])
	assert_eq(topic_total, 100)


func test_photo_choices_pad_from_same_category() -> void:
	var content: Dictionary = _fixture()
	for id: String in content["morph"]:
		content["morph"][id]["confusers"] = []
	var exam := AdaptiveExam.new(content, _rng(23))
	var photos: int = 0
	while not exam.is_done():
		var item: Dictionary = exam.next_item()
		if str(item["id"]).begins_with("morph:"):
			photos += 1
			assert_eq(item["choices"].size(), 4)
		exam.answer(true, 0.0)
	assert_eq(photos, 2)


func test_missing_difficulty_uses_nearest_lower_first() -> void:
	var content: Dictionary = _fixture(false)
	var filtered: Array[Dictionary] = []
	for item: Dictionary in content["questions"]:
		if int(item["difficulty"]) != 2:
			filtered.append(item)
	content["questions"] = filtered
	var exam := AdaptiveExam.new(content, _rng(1))
	assert_eq(int(exam.next_item()["difficulty"]), 1)


func test_seed_reproduces_order_and_choices() -> void:
	var first := AdaptiveExam.new(_fixture(), _rng(88))
	var second := AdaptiveExam.new(_fixture(), _rng(88))
	while not first.is_done():
		assert_eq(first.next_item(), second.next_item())
		first.answer(true, 1.0)
		second.answer(true, 1.0)
	assert_eq(first.results(), second.results())
