extends Control
## Runs a composed shift and commits its earned XP only after completion.

var _params: Dictionary = {}
var _tasks: Array[Dictionary] = []
var _task_label: Label
var _xp_label: Label
var _bench_host: Control
var _leave_dialog: ConfirmationDialog
var _earned_xp: int = 0
var _correct: int = 0
var _total: int = 0
var _finished: bool = false


func setup(params: Dictionary) -> void:
	_params = params.duplicate(true)


func _ready() -> void:
	_build()
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()
	_tasks = ShiftComposer.compose(
		Content.as_dict(), Progress.data, Progress.level(), rng,
		int(Time.get_unix_time_from_system()), 10, String(_params.get("mode", "career")),
		String(_params.get("bench", "")), int(_params.get("tier", 0)), String(_params.get("topic", ""))
	)
	_run_tasks.call_deferred()


func _build() -> void:
	var background := ColorRect.new()
	background.color = ThemeBuilder.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := UI.vbox(8)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	column.add_child(margin)
	var header := UI.hbox()
	margin.add_child(header)
	header.add_child(UI.button("‹ Back", func(): Nav.back(), "SecondaryButton"))
	var status := UI.vbox(4)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status)
	_task_label = UI.label("Preparing shift…", "TitleLabel")
	status.add_child(_task_label)
	_xp_label = UI.label("Shift XP: 0", "MutedLabel")
	status.add_child(_xp_label)
	_bench_host = Control.new()
	_bench_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_bench_host)
	_leave_dialog = UI.confirm_dialog("Leave shift?", "Progress on answered items is saved. The shift completion bonus will not be granted.", "Leave shift", "Keep working")
	_leave_dialog.confirmed.connect(func(): Nav.force_back())
	add_child(_leave_dialog)


func _run_tasks() -> void:
	for index in range(_tasks.size()):
		var task: Dictionary = _tasks[index]
		_task_label.text = "Task %d/%d" % [index + 1, _tasks.size()]
		var bench_script: Script = load("res://scripts/benches/%s_bench.gd" % String(task["bench"]))
		var bench: Variant = bench_script.new()
		_bench_host.add_child(bench)
		bench.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bench.start(task)
		var result: Dictionary = await bench.finished
		_correct += int(result["correct"])
		_total += int(result["total"])
		_earned_xp += int(result["xp"])
		_xp_label.text = "Shift XP: %d" % _earned_xp
		_bench_host.remove_child(bench)
		bench.queue_free()
	_complete_shift()


func _complete_shift() -> void:
	var accuracy: float = float(_correct) / float(_total) if _total > 0 else 0.0
	_earned_xp += XpRules.XP_SHIFT_COMPLETE
	if accuracy >= 0.8:
		_earned_xp += XpRules.XP_SHIFT_ACCURACY_BONUS
	var levels: Dictionary = Progress.add_xp(_earned_xp)
	Progress.shift_completed()
	var weakest_topic: String = ""
	var weakest_mastery: float = INF
	for topic in Topics.ids():
		if Progress.attempts(topic) == 0:
			continue
		var mastery: float = Progress.mastery(topic)
		if mastery < weakest_mastery:
			weakest_mastery = mastery
			weakest_topic = topic
	_finished = true
	Nav.replace("shift_summary", {
		"mode": String(_params.get("mode", "career")),
		"correct": _correct, "total": _total, "accuracy": accuracy,
		"xp_gained": _earned_xp, "old_level": int(levels["old_level"]),
		"new_level": int(levels["new_level"]), "weakest_topic": weakest_topic,
		"bench": String(_params.get("bench", "")), "tier": int(_params.get("tier", 0)),
		"topic": String(_params.get("topic", "")),
	})


func can_leave() -> bool:
	if _finished:
		return true
	UI.popup_confirm(_leave_dialog)
	return false
