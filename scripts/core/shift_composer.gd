class_name ShiftComposer
extends RefCounted
## Pure, seeded composition of career and targeted practice shifts.

static func compose(content: Dictionary, progress: Dictionary, level: int, rng: RandomNumberGenerator, now: int, size: int = 10, mode: String = "career", practice_bench: String = "", practice_tier: int = 0, practice_topic: String = "") -> Array[Dictionary]:
	var tier: int = XpRules.tier_for_level(level)
	if mode == "practice" and practice_tier > 0:
		tier = clampi(practice_tier, 1, 3)
	var slots: Array[String] = []
	if mode == "practice":
		for i in maxi(size, 0):
			slots.append(practice_bench)
	else:
		var benches: Array[String] = XpRules.unlocked_benches(level)
		for bench: String in benches:
			if bench == "knowledge":
				continue
			slots.append(bench)
			if bench == "morphology":
				slots.append(bench)
		while slots.size() < size:
			slots.append("knowledge")
		if slots.size() > maxi(size, 0):
			slots.resize(maxi(size, 0))
	_shuffle(slots, rng)
	if slots.size() > 1 and slots[0] == "differential":
		for i in range(1, slots.size()):
			if slots[i] != "differential":
				var first: String = slots[i]
				slots[i] = slots[0]
				slots[0] = first
				break

	# Choose in presentation order: the first eligible slot receives the oldest due item.
	var tasks: Array[Dictionary] = []
	var used: Dictionary = {}
	var knowledge_index: int = 0
	for bench: String in slots:
		var task: Dictionary = {}
		if bench == "knowledge":
			knowledge_index += 1
			if tier >= 2 and knowledge_index % 4 == 0:
				var types: Array = CalcDrills.TYPES
				# Topic-filtered practice must not introduce a drill from another topic.
				var eligible: Array[String] = []
				for drill_type: String in types:
					var topic: String = "hemo" if drill_type == "inr" else "lab"
					if practice_topic == "" or mode != "practice" or topic == practice_topic:
						eligible.append(drill_type)
				if not eligible.is_empty():
					task = {"bench": bench, "drill": eligible[rng.randi_range(0, eligible.size() - 1)]}
			if task.is_empty():
				var chosen: Dictionary = _pick(_candidates(content.get("questions", []), practice_topic if mode == "practice" else ""), progress, used, tier, rng, now)
				if not chosen.is_empty():
					task = {"bench": bench, "item_id": chosen["id"]}
		elif bench == "morphology":
			var candidates: Array[Dictionary] = []
			var morph: Dictionary = content.get("morph", {})
			var photographed: Dictionary = content.get("photos_by_morph", {})
			for id: String in morph:
				var entity: Dictionary = morph[id]
				if not photographed.has(id):
					continue
				var filter_topic: String = _morph_topic(str(entity.get("category", "")))
				if mode == "practice" and practice_topic != "" and filter_topic != practice_topic:
					continue
				candidates.append({"id": "morph:" + id, "morph_id": id, "topic": "lab", "difficulty": 2})
			var chosen: Dictionary = _pick(candidates, progress, used, tier, rng, now)
			if not chosen.is_empty():
				var id: String = chosen["morph_id"]
				var variant: String = "association" if tier >= 3 and rng.randf() < 0.5 else "identify"
				task = {"bench": bench, "morph_id": id, "variant": variant}
		elif bench == "differential":
			var profiles: Array[Dictionary] = []
			for profile: Dictionary in content.get("diff_profiles", []):
				if int(profile.get("tier", 1)) <= tier:
					profiles.append(profile)
			if not profiles.is_empty():
				task = {"bench": bench, "profile_id": profiles[rng.randi_range(0, profiles.size() - 1)]["id"]}
		elif bench == "cbc" or bench == "coag":
			if bench == "coag" and rng.randf() < 0.25:
				task = {"bench": bench, "variant": "cascade"}
			else:
				var collection: String = "cbc_cases" if bench == "cbc" else "coag_cases"
				var topic_filter: String = practice_topic if mode == "practice" and bench == "cbc" else ""
				var chosen: Dictionary = _pick(_candidates(content.get(collection, []), topic_filter), progress, used, tier, rng, now)
				if not chosen.is_empty():
					task = {"bench": bench, "case_id": chosen["id"]}
		elif bench == "qc":
			var scenarios: Array = QcGenerator.SCENARIOS
			task = {"bench": bench, "scenario": scenarios[rng.randi_range(0, scenarios.size() - 1)]}
		if not task.is_empty():
			task["tier"] = tier
			tasks.append(task)
	return tasks


static func _candidates(items: Array, topic_filter: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in items:
		if topic_filter == "" or item.get("topic", "") == topic_filter:
			result.append(item)
	return result


static func _pick(candidates: Array[Dictionary], progress: Dictionary, used: Dictionary, tier: int, rng: RandomNumberGenerator, now: int) -> Dictionary:
	var entries: Dictionary = progress.get("items", {})
	var due: Array[Dictionary] = []
	var unseen: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for item: Dictionary in candidates:
		var id: String = item["id"]
		if used.has(id):
			continue
		remaining.append(item)
		if not entries.has(id):
			unseen.append(item)
		elif Leitner.is_due(entries[id], now):
			due.append(item)
	var picked: Dictionary = {}
	if not due.is_empty():
		due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(entries[a["id"]].get("due", 0)) < int(entries[b["id"]].get("due", 0)))
		picked = due[0]
	elif not unseen.is_empty():
		var topic_history: Dictionary = progress.get("topics", {})
		var weakest: float = INF
		for item: Dictionary in unseen:
			var topic: String = item.get("topic", "lab")
			var attempts: Array = topic_history.get(topic, [])
			var mastery: float = -1.0 if attempts.size() < 5 else SaveStore.mastery(progress, topic)
			weakest = minf(weakest, mastery)
		var weak_items: Array[Dictionary] = []
		for item: Dictionary in unseen:
			var topic: String = item.get("topic", "lab")
			var attempts: Array = topic_history.get(topic, [])
			var mastery: float = -1.0 if attempts.size() < 5 else SaveStore.mastery(progress, topic)
			if is_equal_approx(mastery, weakest):
				weak_items.append(item)
		picked = _difficulty_pick(weak_items, tier, rng)
	elif not remaining.is_empty():
		picked = _difficulty_pick(remaining, tier, rng)
	if not picked.is_empty():
		used[picked["id"]] = true
	return picked


static func _difficulty_pick(items: Array[Dictionary], tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var roll: float = rng.randf()
	var difficulty: int
	match tier:
		1: difficulty = 1 if roll < 0.7 else 2
		2: difficulty = 1 if roll < 0.3 else (2 if roll < 0.8 else 3)
		_: difficulty = 1 if roll < 0.1 else (2 if roll < 0.6 else 3)
	for distance in range(3):
		for desired in ([difficulty] if distance == 0 else [difficulty - distance, difficulty + distance]):
			var pool: Array[Dictionary] = []
			for item: Dictionary in items:
				if int(item.get("difficulty", 2)) == desired:
					pool.append(item)
			if not pool.is_empty():
				return pool[rng.randi_range(0, pool.size() - 1)]
	return {}


static func _morph_topic(category: String) -> String:
	if category == "wbc" or category == "plt":
		return category
	if category == "rbc" or category == "inclusion":
		return "rbc"
	return "lab"


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: Variant = items[i]
		items[i] = items[j]
		items[j] = value
