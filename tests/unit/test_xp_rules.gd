extends GutTest


func test_level_thresholds_and_cap() -> void:
	assert_eq(XpRules.threshold(1), 0)
	assert_eq(XpRules.threshold(2), 100)
	assert_eq(XpRules.threshold(10), 4500)
	assert_eq(XpRules.level_for_xp(99), 1)
	assert_eq(XpRules.level_for_xp(100), 2)
	assert_eq(XpRules.level_for_xp(4500), 10)
	assert_eq(XpRules.level_for_xp(1000000), 30)
	for level in range(2, 31):
		assert_eq(XpRules.level_for_xp(XpRules.threshold(level)), level)
		assert_eq(XpRules.level_for_xp(XpRules.threshold(level) - 1), level - 1)


func test_ranks_and_tiers() -> void:
	assert_eq(XpRules.rank_for_level(1), "Student Intern")
	assert_eq(XpRules.rank_for_level(3), "MLT Trainee")
	assert_eq(XpRules.rank_for_level(5), "MLT")
	assert_eq(XpRules.rank_for_level(7), "Senior MLT")
	assert_eq(XpRules.rank_for_level(9), "Lead MLT")
	assert_eq(XpRules.tier_for_level(3), 1)
	assert_eq(XpRules.tier_for_level(4), 2)
	assert_eq(XpRules.tier_for_level(6), 2)
	assert_eq(XpRules.tier_for_level(7), 3)


func test_bench_unlock_order() -> void:
	assert_eq(XpRules.unlocked_benches(1), ["knowledge", "morphology"])
	assert_eq(XpRules.unlocked_benches(2), ["knowledge", "morphology", "differential"])
	assert_eq(XpRules.unlocked_benches(5), ["knowledge", "morphology", "differential", "cbc", "coag", "qc"])


func test_xp_awards_and_boundaries() -> void:
	assert_eq(XpRules.XP_PER_CORRECT_PER_DIFFICULTY, 10)
	assert_eq(XpRules.XP_CASE_STEP, 15)
	assert_eq(XpRules.XP_SHIFT_COMPLETE, 50)
	assert_eq(XpRules.XP_SHIFT_ACCURACY_BONUS, 50)
	assert_eq(XpRules.XP_EXAM_COMPLETE, 100)
	assert_eq(XpRules.xp_for_diff(0.9), 40)
	assert_eq(XpRules.xp_for_diff(0.899), 25)
	assert_eq(XpRules.xp_for_diff(0.75), 25)
	assert_eq(XpRules.xp_for_diff(0.749), 10)
	assert_eq(XpRules.xp_for_cascade(14), 28)
	assert_eq(XpRules.xp_to_next(99), 1)
	assert_eq(XpRules.xp_to_next(100), 200)
	assert_eq(XpRules.xp_to_next(1000000), 0)
