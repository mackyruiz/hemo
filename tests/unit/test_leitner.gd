extends GutTest

const NOW := 1700000000


func test_wrong_resets_box_and_is_due_now() -> void:
	var entry: Dictionary = {"box": 3, "due": NOW + 200, "attempts": 8, "correct": 5}
	var updated: Dictionary = Leitner.update(entry, false, NOW)
	assert_eq(updated["box"], 1)
	assert_eq(updated["due"], NOW)
	assert_eq(updated["attempts"], 9)
	assert_eq(updated["correct"], 5)
	assert_eq(entry["box"], 3, "The input entry is not mutated")
	assert_true(Leitner.is_due(updated, NOW))


func test_correct_advances_box_and_schedules_three_days() -> void:
	var updated: Dictionary = Leitner.update({"box": 2, "attempts": 3, "correct": 2}, true, NOW)
	assert_eq(updated["box"], 3)
	assert_eq(updated["due"], NOW + 3 * 86400)
	assert_eq(updated["attempts"], 4)
	assert_eq(updated["correct"], 3)
	assert_false(Leitner.is_due(updated, NOW))
	assert_true(Leitner.is_due(updated, NOW + 3 * 86400))


func test_top_box_stays_five_and_schedules_fourteen_days() -> void:
	var updated: Dictionary = Leitner.update({"box": 5}, true, NOW)
	assert_eq(updated["box"], 5)
	assert_eq(updated["due"], NOW + 14 * 86400)


func test_missing_entry_defaults_and_all_intervals() -> void:
	var correct: Dictionary = Leitner.update({}, true, NOW)
	assert_eq(correct, {"box": 2, "due": NOW + 86400, "attempts": 1, "correct": 1})
	assert_eq(Leitner.update({}, false, NOW), {"box": 1, "due": NOW, "attempts": 1, "correct": 0})
	assert_eq(Leitner.update({"box": 3}, true, NOW)["due"], NOW + 7 * 86400)
	assert_true(Leitner.is_due({}, NOW))
