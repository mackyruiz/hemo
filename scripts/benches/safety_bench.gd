extends Control
## Lab safety: the waste sort, or an illustrated incident with decision steps.

signal finished(result: Dictionary)

var _rng := RandomNumberGenerator.new()
var _correct: int = 0


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var variant: String = String(task.get("variant", ""))
	if variant == "":
		# Direct callers (tests, Lab Floor) get either drill rather than always the sort.
		variant = "scenario" if _rng.randf() < 0.5 else "waste_sort"
	if variant == "scenario":
		_start_scenario()
	else:
		_start_waste_sort()


func _start_waste_sort() -> void:
	var chips: Array[Dictionary] = SafetySort.pick(_rng)
	var sort := ChipSort.new()
	sort.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sort)
	sort.setup("Lab waste sort", "Tap an item in the list, then tap the container it belongs in at the bottom. Tap a placed item to pick it up again.", SafetySort.BINS, chips, _rng, str(Content.generated_sources.get("safety:waste", "")), "item", "container", SafetySort.BIN_ART)
	sort.checked.connect(func(results: Array[bool]):
		var correct: int = 0
		for r: bool in results:
			Progress.record_topic_only("safety", r)
			if r:
				correct += 1
		sort.column.add_child(UI.button("Next", func(): finished.emit({"correct": correct, "total": chips.size(), "xp": XpRules.xp_for_sort(correct)}))))


func _start_scenario() -> void:
	var scenario: Dictionary = SafetyScenarios.pick(_rng)
	var page: Array = UI.page(String(scenario["title"]), false)
	add_child(page[0])
	var column: VBoxContainer = page[1]
	var card: PanelContainer = UI.card()
	var card_column: VBoxContainer = UI.vbox(12)
	card.add_child(card_column)
	card_column.add_child(ScenarioArt.make(String(scenario["art"])))
	card_column.add_child(UI.label(String(scenario["vignette"])))
	column.add_child(card)
	var host: VBoxContainer = UI.vbox(16)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(host)
	_ask_step(scenario, 0, host)


## One QuestionPanel per step; the panel owns feedback, hint, flag and the Next button.
func _ask_step(scenario: Dictionary, index: int, host: VBoxContainer) -> void:
	var steps: Array = scenario["steps"]
	var question: Dictionary = (steps[index] as Dictionary).duplicate(true)
	question["topic"] = "safety"
	question["image"] = null
	var panel := QuestionPanel.new()
	host.add_child(panel)
	panel.setup(question, {"show_feedback": true, "rng": _rng, "flag": {"key": "%s:%d" % [String(scenario["id"]), index]}})
	panel.answered.connect(func(correct: bool, _chosen: int):
		Progress.record_topic_only("safety", correct)
		if correct:
			_correct += 1)
	panel.next_pressed.connect(func():
		host.remove_child(panel)
		panel.queue_free()
		if index + 1 < steps.size():
			_ask_step(scenario, index + 1, host)
		else:
			finished.emit({"correct": _correct, "total": steps.size(), "xp": XpRules.XP_PER_CORRECT_PER_DIFFICULTY * int(scenario["difficulty"]) * _correct}))
