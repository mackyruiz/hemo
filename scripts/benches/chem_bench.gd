extends Control
## Chemistry calculation drills answered on the number pad.

signal finished(result: Dictionary)

var _rng := RandomNumberGenerator.new()
var _content: VBoxContainer
var _drills: Array = []
var _tier: int = 1
var _index: int = 0
var _correct: int = 0
var _xp: int = 0
var _answered: bool = false
var _completed: bool = false


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	_drills = task["drills"]
	_tier = int(task.get("tier", 1))
	var page: Array = UI.page("Chemistry", false)
	add_child(page[0])
	_content = page[1]
	_show_drill()


func _show_drill() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_answered = false
	var drill: Dictionary = ChemCalcs.generate(String(_drills[_index]), _rng)
	_content.add_child(UI.label("Question %d/%d" % [_index + 1, _drills.size()], "MutedLabel"))
	_content.add_child(UI.label(String(drill["stem"])))
	var pad := NumPad.new()
	_content.add_child(pad)
	pad.submitted.connect(func(value: float):
		if _answered:
			return
		_answered = true
		var correct: bool = CalcDrills.is_correct(drill, value)
		Progress.record_topic_only("chem", correct)
		if correct:
			_correct += 1
			_xp += XpRules.XP_PER_CORRECT_PER_DIFFICULTY * _tier
		pad.visible = false
		var decimals: int = int(drill["decimals"])
		var expected: String = String.num(CalcDrills.round_to(float(drill["answer"]), decimals), decimals)
		_content.add_child(UI.label(("✓ Correct" if correct else "✗ Not quite") + " — " + expected + " " + String(drill.get("unit", ""))))
		_content.add_child(UI.label(String(drill["explanation"])))
		var link: Button = UI.source_link(str(Content.generated_sources.get("chem:%s" % drill["type"], "")))
		if link != null:
			_content.add_child(link)
		_content.add_child(UI.button("Next", _next))
	)


func _next() -> void:
	if not _answered or _completed:
		return
	_index += 1
	if _index >= _drills.size():
		_completed = true
		finished.emit({"correct": _correct, "total": _drills.size(), "xp": _xp})
	else:
		_show_drill()
