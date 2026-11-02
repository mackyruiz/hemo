extends GutTest

const DIRECTORY := "user://test_tmp"
const SAVE_PATH := DIRECTORY + "/flag_store_save.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func test_add_has_and_entries_order() -> void:
	var data: Dictionary = {}
	FlagStore.add(data, "b", {"stem": "second"}, 100)
	FlagStore.add(data, "a", {"stem": "third"}, 200)
	FlagStore.add(data, "c", {"stem": "first"}, 100)
	assert_true(FlagStore.has(data, "b"))
	assert_false(FlagStore.has(data, "z"))
	var entries: Array[Dictionary] = FlagStore.entries(data)
	assert_eq(entries.size(), 3)
	assert_eq(str(entries[0]["key"]), "a")
	assert_eq(str(entries[1]["key"]), "b")
	assert_eq(str(entries[2]["key"]), "c")


func test_re_add_overwrites() -> void:
	var data: Dictionary = {}
	FlagStore.add(data, "k", {"stem": "old"}, 100)
	FlagStore.add(data, "k", {"stem": "new"}, 250)
	var entries: Array[Dictionary] = FlagStore.entries(data)
	assert_eq(entries.size(), 1)
	assert_eq(str(entries[0]["q"]["stem"]), "new")
	assert_eq(int(entries[0]["ts"]), 250)


func test_remove_missing_key_is_noop() -> void:
	var data: Dictionary = {}
	FlagStore.remove(data, "gone")
	assert_eq(FlagStore.entries(data).size(), 0)
	FlagStore.add(data, "k", {"stem": "s"}, 7)
	FlagStore.remove(data, "k")
	assert_false(FlagStore.has(data, "k"))


func test_missing_or_bad_flagged_treated_empty() -> void:
	var data: Dictionary = {"flagged": "not a dict"}
	assert_false(FlagStore.has(data, "x"))
	assert_eq(FlagStore.entries(data).size(), 0)
	FlagStore.add(data, "x", {"stem": "s"}, 5)
	assert_true(FlagStore.has(data, "x"))


func test_snapshot_stored_is_independent_copy() -> void:
	var snap: Dictionary = {"stem": "s", "choices": ["a", "b"]}
	var data: Dictionary = {}
	FlagStore.add(data, "k", snap, 1)
	snap["stem"] = "changed"
	assert_eq(str(data["flagged"]["k"]["q"]["stem"]), "s")


func test_old_save_gains_flagged_and_cards_defaults() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"xp": 42}')
	file.close()
	var loaded: Dictionary = SaveStore.load_from(SAVE_PATH)
	assert_eq(int(loaded["xp"]), 42)
	assert_eq(loaded["flagged"], {})
	assert_eq(loaded["cards"], {})

