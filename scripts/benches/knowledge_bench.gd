extends Control
## Knowledge questions and generated numeric drills share one saved response.

signal finished(result: Dictionary)

var _content: VBoxContainer
var _rng := RandomNumberGenerator.new()
var _result: Dictionary = {"correct": 0, "total": 1, "xp": 0}
var _answered: bool = false
var _completed: bool = false


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var page: Array = UI.page("Knowledge", false)
	add_child(page[0])
	_content = page[1]
	if task.has("drill"):
		_show_drill(task)
	else:
		_show_item(task)


func _show_item(task: Dictionary) -> void:
	var question: Dictionary = Content.questions_by_id[String(task["item_id"])]
	var panel := QuestionPanel.new()
	_content.add_child(panel)
	panel.setup(question, {"show_feedback": true, "image_source": "photo" if int(task.get("tier", 1)) >= 2 else "art", "rng": _rng})
	panel.answered.connect(func(correct: bool, _chosen: int):
		if _answered:
			return
		_answered = true
		Progress.record_item(String(question["id"]), String(question["topic"]), correct)
		_result["correct"] = int(correct)
		_result["xp"] = XpRules.XP_PER_CORRECT_PER_DIFFICULTY * int(question["difficulty"]) if correct else 0
	)
	panel.next_pressed.connect(_finish)


func _show_drill(task: Dictionary) -> void:
	var drill: Dictionary = CalcDrills.generate(String(task["drill"]), _rng)
	_content.add_child(UI.label(String(drill["stem"])))
	var pad := NumPad.new()
	_content.add_child(pad)
	pad.submitted.connect(func(value: float):
		if _answered:
			return
		_answered = true
		var correct: bool = CalcDrills.is_correct(drill, value)
		Progress.record_topic_only(String(drill["topic"]), correct)
		_result["correct"] = int(correct)
		_result["xp"] = XpRules.XP_PER_CORRECT_PER_DIFFICULTY * int(task.get("tier", 1)) if correct else 0
		pad.visible = false
		var decimals: int = int(drill["decimals"])
		var expected: String = String.num(CalcDrills.round_to(float(drill["answer"]), decimals), decimals)
		_content.add_child(UI.label(("✓ Correct" if correct else "✗ Not quite") + " — " + expected + " " + String(drill.get("unit", ""))))
		_content.add_child(UI.label(String(drill["explanation"])))
		var link: Button = UI.source_link(str(Content.generated_sources.get("drill:%s" % drill["type"], "")))
		if link != null:
			_content.add_child(link)
		_content.add_child(UI.button("Next", _finish))
	)

func _finish() -> void:
	if _completed or not _answered:
		return
	_completed = true
	finished.emit(_result)
