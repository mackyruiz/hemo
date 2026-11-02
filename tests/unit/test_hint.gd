extends GutTest

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_four_choices_remove_two_wrong_and_vary_the_kept_one() -> void:
	var kept_counts: Dictionary = {}
	for seed_value in range(1, 201):
		var removed: Array[int] = Hint.eliminate(4, 2, _rng(seed_value))
		assert_eq(removed.size(), 2)
		assert_ne(removed[0], removed[1])
		assert_false(2 in removed)
		for index in removed:
			assert_true(index >= 0 and index <= 3)
		for index in [0, 1, 3]:
			if index not in removed:
				kept_counts[index] = true
	assert_eq(kept_counts.size(), 3, "every wrong choice is kept for some seed")

func test_two_choices_are_never_hinted() -> void:
	assert_eq(Hint.eliminate(2, 0, _rng(1)), [] as Array[int])

func test_three_choices_remove_exactly_one_wrong() -> void:
	for seed_value in range(1, 50):
		var removed: Array[int] = Hint.eliminate(3, 1, _rng(seed_value))
		assert_eq(removed.size(), 1)
		assert_ne(removed[0], 1)

func test_out_of_range_answer_removes_nothing() -> void:
	assert_eq(Hint.eliminate(4, 4, _rng(1)), [] as Array[int])
	assert_eq(Hint.eliminate(4, -1, _rng(1)), [] as Array[int])

func test_same_seed_gives_same_result() -> void:
	assert_eq(Hint.eliminate(4, 0, _rng(77)), Hint.eliminate(4, 0, _rng(77)))
