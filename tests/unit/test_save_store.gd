extends GutTest

const DIRECTORY := "user://test_tmp"
const SAVE_PATH := DIRECTORY + "/core_math_save.json"
const CORRUPT_PATH := DIRECTORY + "/save.corrupt.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	_remove_test_files()


func after_each() -> void:
	_remove_test_files()


func _remove_test_files() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".tmp", CORRUPT_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func test_missing_save_returns_independent_defaults() -> void:
	var data: Dictionary = SaveStore.load_from(SAVE_PATH)
	assert_eq(data, SaveStore.defaults())
	data["settings"]["large_text"] = true
	assert_false(SaveStore.defaults()["settings"]["large_text"])
	assert_eq(SaveStore.VERSION, 1)


func test_round_trip_and_atomic_replacement() -> void:
	var data: Dictionary = SaveStore.defaults()
	data["xp"] = 120
	data["items"]["rbc-0001"] = {"box": 3, "due": 1700000000, "attempts": 4, "correct": 3}
	data["topics"]["rbc"] = [true, false, true]
	data["settings"]["large_text"] = true
	data["stats"]["shifts_completed"] = 2
	data["exams"].append({"ts": 1700000000, "score": 0.8, "by_topic": {"rbc": 0.8}, "duration_s": 600.0, "items": ["rbc-0001"]})
	assert_eq(SaveStore.save_to(SAVE_PATH, data), OK)
	var loaded: Dictionary = SaveStore.load_from(SAVE_PATH)
	# JSON represents numbers as floats; compare to the same serialization.
	var expected: Dictionary = JSON.parse_string(JSON.stringify(data))
	assert_eq(loaded, expected)
	assert_false(FileAccess.file_exists(SAVE_PATH + ".tmp"))
	data["xp"] = 500
	assert_eq(SaveStore.save_to(SAVE_PATH, data), OK)
	assert_eq(int(SaveStore.load_from(SAVE_PATH)["xp"]), 500)


func test_corrupt_save_is_backed_up_and_marked_recovered() -> void:
	var raw: String = "{broken save"
	_write_raw(raw)
	var loaded: Dictionary = SaveStore.load_from(SAVE_PATH)
	assert_eq(loaded["xp"], 0)
	assert_true(loaded["_recovered"])
	assert_file_exists(CORRUPT_PATH)
	assert_eq(FileAccess.get_file_as_string(CORRUPT_PATH), raw)
	assert_eq(FileAccess.get_file_as_string(SAVE_PATH), raw)


func test_valid_non_dictionary_is_also_corrupt() -> void:
	_write_raw("[1, 2, 3]")
	var loaded: Dictionary = SaveStore.load_from(SAVE_PATH)
	assert_true(loaded["_recovered"])
	assert_eq(loaded["xp"], 0)
	assert_eq(FileAccess.get_file_as_string(CORRUPT_PATH), "[1, 2, 3]")


func test_partial_save_fills_all_missing_default_keys() -> void:
	_write_raw('{"xp":120,"settings":{}}')
	var loaded: Dictionary = SaveStore.load_from(SAVE_PATH)
	assert_eq(int(loaded["xp"]), 120)
	for key: String in SaveStore.defaults():
		assert_has(loaded, key)
	assert_false(loaded["settings"]["large_text"])
	assert_eq(loaded["stats"]["shifts_completed"], 0)
	assert_false(loaded.has("_recovered"))


func test_topic_window_and_mastery() -> void:
	var data: Dictionary = SaveStore.defaults()
	assert_eq(SaveStore.mastery(data, "lab"), -1.0)
	SaveStore.record_topic(data, "lab", false)
	SaveStore.record_topic(data, "lab", true)
	assert_eq(SaveStore.mastery(data, "lab"), 0.5)
	for i in range(20):
		SaveStore.record_topic(data, "lab", true)
	assert_eq(data["topics"]["lab"].size(), 20)
	assert_eq(SaveStore.mastery(data, "lab"), 1.0)
	assert_eq(SaveStore.mastery(data, "rbc"), -1.0)


func test_deep_merge_does_not_mutate_either_input() -> void:
	var base: Dictionary = {"settings": {"large_text": false, "other": true}, "items": {"a": {"box": 1}}}
	var overlay: Dictionary = {"settings": {"large_text": true}, "new": [1, 2]}
	var merged: Dictionary = SaveStore.deep_merge(base, overlay)
	assert_eq(merged["settings"], {"large_text": true, "other": true})
	assert_eq(merged["items"], {"a": {"box": 1}})
	merged["items"]["a"]["box"] = 4
	merged["new"].append(3)
	assert_eq(base["items"]["a"]["box"], 1)
	assert_eq(overlay["new"], [1, 2])
	assert_false(base["settings"]["large_text"])


func _write_raw(raw: String) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(raw)
	file.close()
