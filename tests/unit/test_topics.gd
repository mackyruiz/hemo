extends GutTest


func test_every_topic_appears_once_in_subtopics_minimums_and_blueprint() -> void:
	var expected: Array = Topics.ids()
	for pair: Array in [["SUBTOPICS", ContentValidator.SUBTOPICS], ["MIN_QUESTIONS", ContentValidator.MIN_QUESTIONS], ["BLUEPRINT", AdaptiveExam.BLUEPRINT]]:
		var actual: Array = []
		actual.assign(pair[1].keys())
		expected.sort()
		actual.sort()
		assert_eq(actual, expected, pair[0] + " keys equal Topics.ids()")


func test_blueprint_totals_one_hundred_items() -> void:
	var total: int = 0
	for topic: String in AdaptiveExam.BLUEPRINT:
		total += int(AdaptiveExam.BLUEPRINT[topic])
	assert_eq(total, 100)


func test_each_topic_belongs_to_exactly_one_area() -> void:
	var seen: Dictionary = {}
	for area: String in Topics.AREAS:
		for topic: String in Topics.AREAS[area]:
			assert_false(seen.has(topic), "%s appears in %s and %s" % [topic, seen.get(topic, ""), area])
			seen[topic] = area
	var listed: Array = seen.keys()
	var expected: Array = Topics.ids()
	listed.sort()
	expected.sort()
	assert_eq(listed, expected)
	for topic: String in Topics.ids():
		assert_true(Topics.NAMES.has(topic), topic + " has a display name")
