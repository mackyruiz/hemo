extends GutTest

## The unlock-everything switch must stay opt-in: the suite runs without the flag, so
## a hardcoded `true` (or a level override that ignores the flag) fails here rather
## than shipping an unlocked release build.


func test_unlock_all_is_off_without_the_flag() -> void:
	assert_false(DebugMode.unlock_all(), "debug unlock must stay opt-in")


func test_level_follows_earned_xp_when_the_flag_is_off() -> void:
	assert_eq(Progress.level(), XpRules.level_for_xp(Progress.xp()))
