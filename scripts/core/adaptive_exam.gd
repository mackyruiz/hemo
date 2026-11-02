class_name AdaptiveExam
extends RefCounted
## A seeded 50-item blueprint with adaptive difficulty and no repeated item ids.

const BLUEPRINT := {"phys": 5, "rbc": 10, "wbc": 10, "plt": 4, "lab": 10, "hemo": 9, "qc": 2}
const DURATION_S: int = 4500

var difficulty: int = 2
var _content: Dictionary
var _rng: RandomNumberGenerator
var _recent: Dictionary = {}
var _used: Dictionary = {}
var _slots: Array[Dictionary] = []
var _index: int = 0
var _current: Dictionary = {}
var _records: Array[Dictionary] = []
var _duration_s: float = 0.0


func _init(content: Dictionary, rng: RandomNumberGenerator, recent_ids: Array = []) -> void:
	_content = content
	_rng = rng
	for id: String in recent_ids:
		_recent[id] = true
	var photo_candidates: Array[Dictionary] = []
	var morph: Dictionary = content.get("morph", {})
	var photos: Dictionary = content.get("photos_by_morph", {})
	for id: String in morph:
		if photos.has(id):
			var item: Dictionary = _morph_item(id)
			if not item.is_empty():
				photo_candidates.append(item)
	_shuffle(photo_candidates)
	# Prefer entities absent from the most recently completed exam.
	var fresh_photos: Array[Dictionary] = []
	var recent_photos: Array[Dictionary] = []
	for item: Dictionary in photo_candidates:
		if _recent.has(item["id"]):
			recent_photos.append(item)
		else:
			fresh_photos.append(item)
	fresh_photos.append_array(recent_photos)
	var photo_count: int = mini(4, fresh_photos.size())
	for topic: String in BLUEPRINT:
		for i in int(BLUEPRINT[topic]):
			var slot: Dictionary = {"topic": topic}
			if topic == "lab" and i < photo_count:
				slot["photo"] = fresh_photos[i]
			_slots.append(slot)
	_shuffle(_slots)


## The same item is returned until answer() commits it.
## Question shape: {id, topic, difficulty, stem, choices, answer, explanation, image}.
func next_item() -> Dictionary:
	if is_done():
		return {}
	if not _current.is_empty():
		return _current
	var slot: Dictionary = _slots[_index]
	if slot.has("photo"):
		_current = slot["photo"]
	else:
		var candidates: Array[Dictionary] = []
		var fresh: Array[Dictionary] = []
		for item: Dictionary in _content.get("questions", []):
			if item.get("topic", "") != slot["topic"] or _used.has(item["id"]):
				continue
			candidates.append(item)
			if not _recent.has(item["id"]):
				fresh.append(item)
		_current = _pick_at_difficulty(fresh if not fresh.is_empty() else candidates)
	return _current


func answer(correct: bool, elapsed_s: float, chosen: int = -1) -> void:
	if _current.is_empty() or is_done():
		return
	_used[_current["id"]] = true
	_records.append({"id": _current["id"], "correct": correct, "chosen": chosen, "item": _current.duplicate(true)})
	_duration_s += maxf(0.0, elapsed_s)
	difficulty = mini(3, difficulty + 1) if correct else maxi(1, difficulty - 1)
	_index += 1
	_current = {}


func is_done() -> bool:
	return _index >= _slots.size()


func count_answered() -> int:
	return _records.size()


func mark_timeout() -> void:
	while not is_done():
		var item: Dictionary = next_item()
		if item.is_empty():
			# An exhausted content bank cannot supply another unique blueprint item.
			_index = _slots.size()
			break
		answer(false, 0.0, -1)
	_duration_s = maxf(_duration_s, float(DURATION_S))


func results() -> Dictionary:
	var correct: int = 0
	var by_topic: Dictionary = {}
	for topic: String in BLUEPRINT:
		by_topic[topic] = {"correct": 0, "total": 0}
	for record: Dictionary in _records:
		var item: Dictionary = record["item"]
		var topic: String = item["topic"]
		by_topic[topic]["total"] += 1
		if record["correct"]:
			correct += 1
			by_topic[topic]["correct"] += 1
	var total: int = _records.size()
	return {
		"score": float(correct) / total if total > 0 else 0.0,
		"correct": correct, "total": total, "by_topic": by_topic,
		"items": _records.duplicate(true), "duration_s": _duration_s,
	}


func _pick_at_difficulty(candidates: Array[Dictionary]) -> Dictionary:
	for distance in range(3):
		for desired in ([difficulty] if distance == 0 else [difficulty - distance, difficulty + distance]):
			var pool: Array[Dictionary] = []
			for item: Dictionary in candidates:
				if int(item["difficulty"]) == desired:
					pool.append(item)
			if not pool.is_empty():
				return pool[_rng.randi_range(0, pool.size() - 1)].duplicate(true)
	return {}


func _morph_item(id: String) -> Dictionary:
	var morph: Dictionary = _content.get("morph", {})
	var entity: Dictionary = morph[id]
	var correct_name: String = entity["name"]
	var names: Array[String] = []
	for confuser: String in entity.get("confusers", []):
		if morph.has(confuser):
			var name: String = morph[confuser]["name"]
			if name != correct_name and not names.has(name):
				names.append(name)
	_shuffle(names)
	if names.size() < 3:
		var padding: Array[String] = []
		for other_id: String in morph:
			var other: Dictionary = morph[other_id]
			var name: String = other["name"]
			if other.get("category", "") == entity.get("category", "") and name != correct_name and not names.has(name):
				padding.append(name)
		_shuffle(padding)
		for name: String in padding:
			if not names.has(name):
				names.append(name)
			if names.size() >= 3:
				break
	if names.size() < 3:
		return {}
	names.resize(3)
	var answer_index: int = _rng.randi_range(0, 3)
	names.insert(answer_index, correct_name)
	return {
		"id": "morph:" + id, "topic": "lab", "subtopic": "differential_morphology",
		"difficulty": 2, "stem": "Identify the cell/finding indicated.",
		"choices": names, "answer": answer_index, "image": id,
		"explanation": str(entity.get("features", "")),
	}


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var value: Variant = items[i]
		items[i] = items[j]
		items[j] = value
