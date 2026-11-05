class_name QuestionSeriesBench
extends Control
## Shared flow for subject benches: one QuestionPanel at a time, each optionally
## preceded by a report card, then a single finished result.

signal finished(result: Dictionary)

var _rng := RandomNumberGenerator.new()
var _question_host: VBoxContainer
var _topic: String = ""
var _steps: Array[Dictionary] = []
var _index: int = 0
var _correct: int = 0
var _xp: int = 0
var _answered: bool = false
var _completed: bool = false


## Steps are {"q": QuestionPanel dict, "lines": Array of report lines (may be empty)}.
## Every question's source is filled from the generated source for source_key.
func run(title: String, topic: String, source_key: String, steps: Array[Dictionary]) -> void:
	_topic = topic
	_steps = steps
	var source_id: String = str(Content.generated_sources.get(source_key, ""))
	for step: Dictionary in _steps:
		step["q"]["source"] = source_id
	var page: Array = UI.page(title, false)
	add_child(page[0])
	_question_host = UI.vbox()
	_question_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page[1].add_child(_question_host)
	_show_question()


func _show_question() -> void:
	for child in _question_host.get_children():
		_question_host.remove_child(child)
		child.queue_free()
	_answered = false
	_question_host.add_child(UI.label("Question %d/%d" % [_index + 1, _steps.size()], "MutedLabel"))
	var lines: Array = _steps[_index].get("lines", [])
	if not lines.is_empty():
		var card := UI.card()
		var report := UI.vbox(4)
		card.add_child(report)
		for line: String in lines:
			report.add_child(UI.label(line))
		_question_host.add_child(card)
	var panel := QuestionPanel.new()
	_question_host.add_child(panel)
	panel.setup(_steps[_index]["q"], {"show_feedback": true, "rng": _rng})
	panel.answered.connect(func(correct: bool, _chosen: int):
		if _answered:
			return
		_answered = true
		Progress.record_topic_only(_topic, correct)
		if correct:
			_correct += 1
			_xp += XpRules.XP_PER_CORRECT_PER_DIFFICULTY
	)
	panel.next_pressed.connect(func():
		if not _answered or _completed:
			return
		_index += 1
		if _index >= _steps.size():
			_completed = true
			finished.emit({"correct": _correct, "total": _steps.size(), "xp": _xp})
		else:
			_show_question()
	)
