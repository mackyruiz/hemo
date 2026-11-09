extends Node
## Every mutation is saved immediately; user:// is persisted by Godot on the web.

const SAVE_PATH := "user://save.json"

var data: Dictionary = {}
var _recovered: bool = false


func _ready() -> void:
	data = SaveStore.load_from(SAVE_PATH)
	_recovered = bool(data.get("_recovered", false))
	data.erase("_recovered")
	_apply_theme()


func record_item(id: String, topic: String, correct: bool) -> void:
	var items: Dictionary = data["items"]
	var entry: Dictionary = items.get(id, {})
	items[id] = Leitner.update(entry, correct, int(Time.get_unix_time_from_system()))
	SaveStore.record_topic(data, topic, correct)
	_save()


func record_topic_only(topic: String, correct: bool) -> void:
	SaveStore.record_topic(data, topic, correct)
	_save()


func flag(key: String, snapshot: Dictionary) -> void:
	FlagStore.add(data, key, snapshot, int(Time.get_unix_time_from_system()))
	_save()


func unflag(key: String) -> void:
	FlagStore.remove(data, key)
	_save()


func is_flagged(key: String) -> bool:
	return FlagStore.has(data, key)


func flagged() -> Array[Dictionary]:
	return FlagStore.entries(data)


func record_card(key: String, known: bool) -> void:
	var cards: Dictionary = data["cards"]
	cards[key] = Leitner.update(cards.get(key, {}), known, int(Time.get_unix_time_from_system()))
	_save()


func add_xp(n: int) -> Dictionary:
	var old_level: int = level()
	data["xp"] = xp() + n
	_save()
	return {"old_level": old_level, "new_level": level()}


## Debug builds report the maximum level so every bench is reachable; XP is still
## accumulated and saved, so the real level returns as soon as the flag is off.
func level() -> int:
	return XpRules.MAX_LEVEL if DebugMode.unlock_all() else XpRules.level_for_xp(xp())


func xp() -> int:
	return int(data.get("xp", 0))


func record_exam(stored: Dictionary) -> void:
	var exams: Array = data["exams"]
	exams.append(stored.duplicate(true))
	while exams.size() > 20:
		exams.pop_front()
	_save()


func shift_completed() -> void:
	var stats: Dictionary = data["stats"]
	stats["shifts_completed"] = int(stats.get("shifts_completed", 0)) + 1
	_save()


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	_save()
	if key == "large_text":
		_apply_theme()


func reset() -> void:
	data = SaveStore.defaults()
	_recovered = false
	_save()
	_apply_theme()


func is_persistent() -> bool:
	return not OS.has_feature("web") or OS.is_userfs_persistent()


func consume_recovered() -> bool:
	var recovered: bool = _recovered
	_recovered = false
	return recovered


func due_count() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	var count: int = 0
	var items: Dictionary = data.get("items", {})
	for entry in items.values():
		if Leitner.is_due(entry, now):
			count += 1
	return count


func mastery(topic: String) -> float:
	return SaveStore.mastery(data, topic)


func attempts(topic: String) -> int:
	var topics: Dictionary = data.get("topics", {})
	var history: Array = topics.get(topic, [])
	return history.size()


func _apply_theme() -> void:
	var settings: Dictionary = data.get("settings", {})
	get_tree().root.theme = ThemeBuilder.build(bool(settings.get("large_text", false)))


func _save() -> void:
	var error: Error = SaveStore.save_to(SAVE_PATH, data)
	if error != OK:
		push_error("Could not save HemoShift progress: %s" % error_string(error))
