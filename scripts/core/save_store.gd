class_name SaveStore
extends RefCounted

const VERSION := 1


static func defaults() -> Dictionary:
	return {"version": VERSION, "xp": 0, "items": {}, "topics": {}, "exams": [], "settings": {"large_text": false}, "stats": {"shifts_completed": 0}, "flagged": {}, "cards": {}}


## Returns an independent merged value; nested default keys are preserved.
static func deep_merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate(true)
	for key: Variant in overlay:
		var value: Variant = overlay[key]
		if merged.has(key) and merged[key] is Dictionary and value is Dictionary:
			merged[key] = deep_merge(merged[key], value)
		elif value is Dictionary or value is Array:
			merged[key] = value.duplicate(true)
		else:
			merged[key] = value
	return merged


static func load_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return defaults()
	var raw: String = FileAccess.get_file_as_string(path)
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		DirAccess.copy_absolute(path, path.get_base_dir().path_join("save.corrupt.json"))
		var recovered: Dictionary = defaults()
		recovered["_recovered"] = true
		return recovered
	return deep_merge(defaults(), parser.data)


static func save_to(path: String, data: Dictionary) -> Error:
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return dir_error
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	return DirAccess.rename_absolute(path + ".tmp", path)


static func record_topic(data: Dictionary, topic: String, correct: bool) -> void:
	if not data.has("topics"):
		data["topics"] = {}
	var topics: Dictionary = data["topics"]
	if not topics.has(topic):
		topics[topic] = []
	var attempts: Array = topics[topic]
	attempts.append(correct)
	while attempts.size() > 20:
		attempts.pop_front()


static func mastery(data: Dictionary, topic: String) -> float:
	var topics: Dictionary = data.get("topics", {})
	var attempts: Array = topics.get(topic, [])
	if attempts.is_empty():
		return -1.0
	var correct: int = 0
	for result: bool in attempts:
		if result:
			correct += 1
	return float(correct) / float(attempts.size())
