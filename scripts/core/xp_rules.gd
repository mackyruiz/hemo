class_name XpRules
extends RefCounted

const MAX_LEVEL := 30
const BENCH_UNLOCK := {"knowledge": 1, "morphology": 1, "differential": 2, "cbc": 3, "coag": 4, "qc": 5}
const XP_PER_CORRECT_PER_DIFFICULTY := 10
const XP_CASE_STEP := 15
const XP_SHIFT_COMPLETE := 50
const XP_SHIFT_ACCURACY_BONUS := 50
const XP_EXAM_COMPLETE := 100


static func threshold(level: int) -> int:
	return 50 * level * (level - 1)


static func level_for_xp(xp: int) -> int:
	var level: int = 1
	while level < MAX_LEVEL and threshold(level + 1) <= xp:
		level += 1
	return level


static func rank_for_level(level: int) -> String:
	if level <= 2:
		return "Student Intern"
	if level <= 4:
		return "MLT Trainee"
	if level <= 6:
		return "MLT"
	if level <= 8:
		return "Senior MLT"
	return "Lead MLT"


static func tier_for_level(level: int) -> int:
	if level <= 3:
		return 1
	if level <= 6:
		return 2
	return 3


static func unlocked_benches(level: int) -> Array[String]:
	var benches: Array[String] = []
	for bench: String in BENCH_UNLOCK:
		if level >= int(BENCH_UNLOCK[bench]):
			benches.append(bench)
	return benches


static func xp_for_diff(accuracy: float) -> int:
	if accuracy >= 0.9:
		return 40
	if accuracy >= 0.75:
		return 25
	return 10


static func xp_for_find(hits: int, misses: int) -> int:
	return maxi(0, 5 * hits - 2 * misses)


static func xp_for_cascade(correct_chips: int) -> int:
	return 2 * correct_chips


static func xp_to_next(xp: int) -> int:
	var level: int = level_for_xp(xp)
	return 0 if level == MAX_LEVEL else threshold(level + 1) - xp
