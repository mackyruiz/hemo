class_name FlagStore
extends RefCounted
## Pure save-data helpers for flagged questions. All calls tolerate a
## missing or non-Dictionary `data["flagged"]` as empty.

static func _flags(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("flagged", {})
	return raw if raw is Dictionary else {}

static func add(data: Dictionary, key: String, snapshot: Dictionary, now: int) -> void:
	if not (data.get("flagged") is Dictionary):
		data["flagged"] = {}
	data["flagged"][key] = {"q": snapshot.duplicate(true), "ts": now}

static func remove(data: Dictionary, key: String) -> void:
	_flags(data).erase(key)

static func has(data: Dictionary, key: String) -> bool:
	return _flags(data).has(key)

static func entries(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var flags: Dictionary = _flags(data)
	for key: String in flags:
		result.append({"key": key, "q": flags[key].get("q", {}), "ts": int(flags[key].get("ts", 0))})
	result.sort_custom(_newer_first)
	return result

static func _newer_first(a: Dictionary, b: Dictionary) -> bool:
	if int(a["ts"]) != int(b["ts"]):
		return int(a["ts"]) > int(b["ts"])
	return str(a["key"]) < str(b["key"])
