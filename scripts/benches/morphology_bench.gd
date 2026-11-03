extends Control
## Identification and clinical associations from photomicrographs.

signal finished(result: Dictionary)

var _rng := RandomNumberGenerator.new()
var _content: VBoxContainer
var _task: Dictionary
var _entity: Dictionary
var _result: Dictionary = {"correct": 0, "total": 1, "xp": 0}
var _answered: bool = false
var _completed: bool = false


func start(task: Dictionary) -> void:
	_task = task
	_rng.seed = Time.get_ticks_usec()
	_entity = Content.morph[String(task["morph_id"])]
	var page: Array = UI.page("Morphology", false)
	add_child(page[0])
	_content = page[1]
	_show_question()


func _shuffle(values: Array[String]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var other: int = _rng.randi_range(0, i)
		var previous: String = values[i]
		values[i] = values[other]
		values[other] = previous


func _show_question() -> void:
	var association: bool = String(_task.get("variant", "identify")) == "association"
	var correct_text: String = String(_entity["name"])
	var candidates: Array[String] = []
	if association:
		var associations: Array = _entity["associations"]
		correct_text = String(associations[_rng.randi_range(0, associations.size() - 1)])
	for confuser_id in _entity["confusers"]:
		_add_candidates(Content.morph[String(confuser_id)], association, candidates)
	_shuffle(candidates)
	# Existing confusers lead; same-category entries only pad an unusually small pool.
	if candidates.size() < 3:
		for id in Content.morph:
			var entity: Dictionary = Content.morph[id]
			if id != _task["morph_id"] and entity["category"] == _entity["category"]:
				_add_candidates(entity, association, candidates)
	if candidates.size() < 3:
		for id in Content.morph:
			if id != _task["morph_id"]:
				_add_candidates(Content.morph[id], association, candidates)
	var choices: Array[String] = [correct_text]
	for i in range(3):
		choices.append(candidates[i])
	var explanation: String = String(_entity["features"])
	if association:
		explanation += " Associated conditions include: " + "; ".join(_entity["associations"]) + "."
	var question: Dictionary = {
		"stem": "The circled finding is most associated with:" if association else "Identify the circled cell or finding.",
		"choices": choices, "answer": 0, "explanation": explanation,
		"image": String(_task["morph_id"]), "source": String(_entity.get("source", ""))
	}
	var panel := QuestionPanel.new()
	_content.add_child(panel)
	panel.setup(question, {"show_feedback": true, "rng": _rng, "flag": {"key": "morph:%s:%s" % [String(_task["morph_id"]), "association" if association else "identify"]}})
	panel.answered.connect(func(correct: bool, _chosen: int):
		if _answered:
			return
		_answered = true
		_record(correct, XpRules.XP_PER_CORRECT_PER_DIFFICULTY * int(_task.get("tier", 1)) if correct else 0)
	)
	panel.next_pressed.connect(_finish)


func _add_candidates(entity: Dictionary, association: bool, candidates: Array[String]) -> void:
	if association:
		for entry in entity["associations"]:
			var text: String = String(entry)
			if not _entity["associations"].has(text) and not candidates.has(text):
				candidates.append(text)
	else:
		var text: String = String(entity["name"])
		if text != String(_entity["name"]) and not candidates.has(text):
			candidates.append(text)


func _record(correct: bool, xp: int) -> void:
	Progress.record_item("morph:" + String(_task["morph_id"]), "lab", correct)
	_result["correct"] = int(correct)
	_result["xp"] = xp


func _finish() -> void:
	if _completed or not _answered:
		return
	_completed = true
	finished.emit(_result)
