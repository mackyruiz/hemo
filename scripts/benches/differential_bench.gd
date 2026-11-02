extends Control
## A manual differential with reversible counting and saved follow-up answers.

signal finished(result: Dictionary)

const CLASS_LABELS := {
	"seg": "Segmented neutrophil", "band": "Band neutrophil", "lymph": "Lymphocyte",
	"var_lymph": "Reactive lymphocyte", "mono": "Monocyte", "eos": "Eosinophil",
	"baso": "Basophil", "meta": "Metamyelocyte", "myelo": "Myelocyte",
	"promyelo": "Promyelocyte", "blast": "Blast", "nrbc": "nRBC"
}
const SHORT_LABELS := {
	"seg": "Segmented", "band": "Band", "lymph": "Lymphocyte", "var_lymph": "Reactive lymph",
	"mono": "Monocyte", "eos": "Eosinophil", "baso": "Basophil", "meta": "Metamyelocyte",
	"myelo": "Myelocyte", "promyelo": "Promyelocyte", "blast": "Blast", "nrbc": "nRBC"
}
const SHORTCUTS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

var _rng := RandomNumberGenerator.new()
var _content: VBoxContainer
var _profile: Dictionary
var _generated: Dictionary
var _sequence: Array = []
var _classes: Array[String] = []
var _history: Array[String] = []
var _counts: Dictionary = {}
var _buttons: Dictionary = {}
var _counter: Label
var _cell_holder: CenterContainer
var _undo: Button
var _count_done: Button
var _counting: bool = true
var _correct: int = 0
var _total: int = 0
var _xp: int = 0
var _completed: bool = false
var _numeric_answered: bool = false
var _final_answered: bool = false
var _art_seed: int = 0


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	_art_seed = _rng.randi()
	_profile = Content.profile(String(task["profile_id"]))
	_generated = DiffGenerator.generate(_profile, _rng)
	_sequence = _generated["sequence"]
	for cls in DiffGenerator.TIER_CLASSES[int(task.get("tier", 1))]:
		_classes.append(String(cls))
	if int(task.get("tier", 1)) >= 2:
		_classes.append("nrbc")
	for cls in _classes:
		_counts[cls] = 0
	var page: Array = UI.page("Manual differential", false)
	add_child(page[0])
	_content = page[1]
	_show_counting()


func _show_counting() -> void:
	_counter = UI.label("WBC counted: 0/100")
	_content.add_child(_counter)
	_content.add_child(UI.label("Classify each cell. nRBCs are counted separately. Undo corrects your last tap before you submit.", "MutedLabel"))
	var cell_space := Control.new()
	cell_space.custom_minimum_size.y = 240
	_content.add_child(cell_space)
	_cell_holder = CenterContainer.new()
	_cell_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cell_space.add_child(_cell_holder)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for i in range(_classes.size()):
		var cls: String = _classes[i]
		var button: Button = UI.button("", _classify.bind(cls), "SecondaryButton")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)
		_buttons[cls] = button
	_undo = UI.button("Undo", _undo_count, "SecondaryButton")
	_content.add_child(_undo)
	_count_done = UI.button("Continue to results", _submit_count)
	_count_done.visible = false
	_content.add_child(_count_done)
	_update_counting()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _counting or not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	var code: int = key.physical_keycode if key.physical_keycode != 0 else key.keycode
	var index: int = SHORTCUTS.find(code)
	if index >= 0 and index < _classes.size():
		_classify(_classes[index])
		get_viewport().set_input_as_handled()


func _classify(cls: String) -> void:
	if not _counting or _history.size() >= _sequence.size():
		return
	_history.append(cls)
	_counts[cls] = int(_counts.get(cls, 0)) + 1
	_update_counting()


func _undo_count() -> void:
	if not _counting or _history.is_empty():
		return
	var cls: String = _history.pop_back()
	_counts[cls] = int(_counts[cls]) - 1
	_update_counting()


func _update_counting() -> void:
	var wbc_count: int = _history.size() - int(_counts.get("nrbc", 0))
	_counter.text = "WBC counted: %d/100" % wbc_count
	if _classes.has("nrbc"):
		_counter.text += " · nRBC: %d" % int(_counts.get("nrbc", 0))
	var exhausted: bool = _history.size() >= _sequence.size()
	for i in range(_classes.size()):
		var cls: String = _classes[i]
		var button: Button = _buttons[cls]
		var shortcut: String = " [%s]" % (str(i + 1) if i < 9 else "0") if i < 10 else ""
		button.text = "%s%s\n%d" % [String(SHORT_LABELS[cls]), shortcut, int(_counts[cls])]
		button.disabled = exhausted
	_undo.disabled = _history.is_empty()
	_count_done.visible = exhausted
	for child in _cell_holder.get_children():
		_cell_holder.remove_child(child)
		child.queue_free()
	if exhausted:
		var done_label: Label = UI.label("All cells reviewed.\nContinue to compare your counts.")
		done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Autowrapped labels have no intrinsic width inside a CenterContainer.
		done_label.custom_minimum_size.x = 520
		_cell_holder.add_child(done_label)
	else:
		var cls: String = String(_sequence[_history.size()])
		var morph_id: String = String(DiffGenerator.CLASS_MORPH[cls])
		var descriptor: Dictionary = Content.morph[morph_id]["art"]
		_cell_holder.add_child(CellArt.make(descriptor, _art_seed + _history.size(), 110.0))


func _submit_count() -> void:
	if not _counting or _history.size() != _sequence.size():
		return
	_counting = false
	var cell_correct: int = 0
	for i in range(_sequence.size()):
		var correct: bool = _history[i] == String(_sequence[i])
		cell_correct += int(correct)
		Progress.record_topic_only("lab", correct)
	_correct = cell_correct
	_total = _sequence.size()
	var accuracy: float = float(cell_correct) / float(_sequence.size())
	_xp = 40 if accuracy >= 0.9 else (25 if accuracy >= 0.75 else 10)
	_clear_content()
	_content.add_child(UI.label("Differential accuracy: %.1f%%" % (accuracy * 100.0)))
	_content.add_child(UI.label("Patient WBC: %.1f ×10³/µL" % float(_generated["wbc"])))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for heading in ["Class", "Your %", "Actual %"]:
		_add_table_label(grid, heading)
	var actual_counts: Dictionary = _generated["counts"]
	var player_wbc: int = _history.size() - int(_counts.get("nrbc", 0))
	for cls in DiffGenerator.CLASSES:
		if int(actual_counts.get(cls, 0)) == 0 and int(_counts.get(cls, 0)) == 0:
			continue
		_add_table_label(grid, String(SHORT_LABELS[cls]))
		_add_table_label(grid, "%.1f" % (100.0 * float(_counts.get(cls, 0)) / float(maxi(player_wbc, 1))))
		_add_table_label(grid, str(actual_counts.get(cls, 0)))
	if _classes.has("nrbc"):
		_content.add_child(UI.label("nRBC per 100 WBC: yours %.1f · actual %d" % [100.0 * float(_counts.get("nrbc", 0)) / float(maxi(player_wbc, 1)), int(_generated["nrbc"])]))
	_content.add_child(UI.label("Percentages use your classified WBC total; nRBCs are excluded from the WBC differential.", "MutedLabel"))
	_content.add_child(UI.button("Continue", _show_absolute))


func _add_table_label(grid: GridContainer, text: String) -> void:
	var label: Label = UI.label(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)


func _clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


func _show_absolute() -> void:
	var counts: Dictionary = _generated["counts"]
	var target: String = "seg"
	if String(_profile["id"]) != "normal_adult":
		var largest: int = -1
		for cls in DiffGenerator.CLASSES:
			if cls != "seg" and int(counts.get(cls, 0)) > largest:
				largest = int(counts.get(cls, 0))
				target = String(cls)
	var wbc: float = float(_generated["wbc"])
	var pct: float = float(counts.get(target, 0))
	var expected: float = HemeCalc.absolute(wbc, pct)
	var stem: String = "Calculate the absolute %s count. WBC = %.1f ×10³/µL; actual differential = %.0f%%. Round to 1 decimal place." % [String(CLASS_LABELS[target]).to_lower(), wbc, pct]
	var explanation: String = "Absolute count = WBC × percentage / 100 = %.1f × %.0f / 100 = %.1f ×10³/µL." % [wbc, pct, CalcDrills.round_to(expected, 1)]
	_show_numeric(stem, expected, explanation, _after_absolute, "drill:absolute")


func _after_absolute() -> void:
	if int(_generated["nrbc"]) > 0:
		_show_corrected_wbc()
	else:
		_show_diagnosis()


func _show_corrected_wbc() -> void:
	var wbc: float = float(_generated["wbc"])
	var nrbc: int = int(_generated["nrbc"])
	var expected: float = HemeCalc.corrected_wbc(wbc, nrbc)
	var stem: String = "An uncorrected WBC is %.1f ×10³/µL with %d nRBC per 100 WBC. Calculate the corrected WBC. Round to 1 decimal place." % [wbc, nrbc]
	var explanation: String = "Corrected WBC = WBC × 100 / (100 + nRBC) = %.1f × 100 / (100 + %d) = %.1f ×10³/µL." % [wbc, nrbc, CalcDrills.round_to(expected, 1)]
	_show_numeric(stem, expected, explanation, _show_diagnosis, "drill:corrected_wbc")


func _show_numeric(stem: String, expected: float, explanation: String, next: Callable, source_key: String) -> void:
	_clear_content()
	_numeric_answered = false
	_content.add_child(UI.label(stem))
	var pad := NumPad.new()
	_content.add_child(pad)
	pad.submitted.connect(func(value: float):
		if _numeric_answered:
			return
		_numeric_answered = true
		var correct: bool = CalcDrills.is_correct({"answer": expected, "decimals": 1}, value)
		_record_followup(correct)
		pad.visible = false
		_content.add_child(UI.label(("✓ Correct" if correct else "✗ Not quite") + " — %.1f ×10³/µL" % CalcDrills.round_to(expected, 1)))
		_content.add_child(UI.label(explanation))
		var link: Button = UI.source_link(str(Content.generated_sources.get(source_key, "")))
		if link != null:
			_content.add_child(link)
		_content.add_child(UI.button("Next", next))
	)


func _show_diagnosis() -> void:
	_clear_content()
	var alternatives: Array[String] = []
	for profile in Content.diff_profiles:
		if profile["id"] != _profile["id"]:
			alternatives.append(String(profile["label"]))
	for i in range(alternatives.size() - 1, 0, -1):
		var other: int = _rng.randi_range(0, i)
		var previous: String = alternatives[i]
		alternatives[i] = alternatives[other]
		alternatives[other] = previous
	var choices: Array[String] = [String(_profile["label"])]
	for i in range(3):
		choices.append(alternatives[i])
	var question: Dictionary = {
		"stem": "Most consistent with:", "choices": choices, "answer": 0, "image": null,
		"source": String(Content.generated_sources.get("diff:" + String(_profile["id"]), "")),
		"explanation": "The overall differential pattern is most consistent with %s. Interpret a differential together with the clinical history, CBC, and smear findings, not as a stand-alone diagnosis." % String(_profile["label"]).to_lower()
	}
	var panel := QuestionPanel.new()
	_content.add_child(panel)
	panel.setup(question, {"show_feedback": true, "rng": _rng})
	panel.answered.connect(func(correct: bool, _chosen: int):
		if _final_answered:
			return
		_final_answered = true
		_record_followup(correct)
	)
	panel.next_pressed.connect(_finish)


func _record_followup(correct: bool) -> void:
	Progress.record_topic_only("lab", correct)
	_total += 1
	_correct += int(correct)
	if correct:
		_xp += 10


func _finish() -> void:
	if _completed or not _final_answered:
		return
	_completed = true
	finished.emit({"correct": _correct, "total": _total, "xp": _xp})
