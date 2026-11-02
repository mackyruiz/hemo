extends Control
## Coagulation cases and tap-to-sort coagulation pathway practice.

signal finished(result: Dictionary)

const CASE_BENCH := preload("res://scripts/benches/cbc_bench.gd")
const BINS := ["Intrinsic (APTT only)", "Extrinsic (PT only)", "Common (PT and APTT)", "Not detected by PT/APTT"]
const CHIPS := [
	{"name": "XII", "bin": 0}, {"name": "XI", "bin": 0},
	{"name": "IX", "bin": 0}, {"name": "VIII", "bin": 0},
	{"name": "Prekallikrein", "bin": 0}, {"name": "HMWK", "bin": 0},
	{"name": "VII", "bin": 1}, {"name": "Tissue factor", "bin": 1},
	{"name": "X", "bin": 2}, {"name": "V", "bin": 2},
	{"name": "II (prothrombin)", "bin": 2}, {"name": "I (fibrinogen)", "bin": 2},
	{"name": "XIII", "bin": 3}, {"name": "Protein C", "bin": 3},
]

var _buttons: Array[Button] = []
var _bin_hosts: Array[VBoxContainer] = []
var _assignments: Dictionary = {}
var _selected: int = -1
var _selection_label: Label
var _check_button: Button
var _checked: bool = false
var _correct: int = 0


func start(task: Dictionary) -> void:
	if String(task.get("variant", "case")) != "cascade":
		var case_view := CASE_BENCH.new()
		case_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(case_view)
		case_view.finished.connect(func(result: Dictionary): finished.emit(result))
		case_view.start(task)
		return
	_build_cascade()


func _build_cascade() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column := UI.vbox(16)
	margin.add_child(column)
	column.add_child(UI.label("Coagulation pathway sort", "TitleLabel"))
	column.add_child(UI.label("Tap a chip, then tap a bin to place it. You can select and move a chip again before checking."))
	_selection_label = UI.label("No chip selected", "MutedLabel")
	column.add_child(_selection_label)
	var pool := UI.vbox(8)
	column.add_child(pool)
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for index in range(CHIPS.size()):
		var chip: Dictionary = CHIPS[index]
		var button := UI.button(String(chip["name"]), _select_chip.bind(index), "SecondaryButton")
		button.toggle_mode = true
		button.button_group = group
		_buttons.append(button)
	var order: Array[int] = []
	for index in range(CHIPS.size()):
		order.append(index)
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()
	for index in range(order.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, index)
		var old: int = order[index]
		order[index] = order[swap]
		order[swap] = old
	for index in order:
		pool.add_child(_buttons[index])
	for index in range(BINS.size()):
		var card := UI.card()
		var bin_column := UI.vbox(8)
		card.add_child(bin_column)
		bin_column.add_child(UI.button(String(BINS[index]) + "\nTap to place selected chip", _place_chip.bind(index), "SecondaryButton"))
		var host := UI.vbox(8)
		bin_column.add_child(host)
		_bin_hosts.append(host)
		column.add_child(card)
	_check_button = UI.button("Check", _check)
	column.add_child(_check_button)
	var next_button := UI.button("Next", func(): finished.emit({"correct": _correct, "total": CHIPS.size(), "xp": XpRules.xp_for_cascade(_correct)}))
	next_button.visible = false
	column.add_child(next_button)
	_check_button.pressed.connect(func(): next_button.visible = _checked)


func _select_chip(index: int) -> void:
	if _checked:
		return
	_selected = index if _buttons[index].button_pressed else -1
	_selection_label.text = "Selected: %s" % String(CHIPS[index]["name"]) if _selected >= 0 else "No chip selected"


func _place_chip(bin_index: int) -> void:
	if _checked:
		return
	if _selected < 0:
		UI.toast(self, "Select a chip first.")
		return
	var button: Button = _buttons[_selected]
	if button.get_parent() != _bin_hosts[bin_index]:
		button.reparent(_bin_hosts[bin_index])
	_assignments[_selected] = bin_index
	button.set_pressed_no_signal(false)
	_selected = -1
	_selection_label.text = "Chip placed. Select another chip to continue."


func _check() -> void:
	if _checked:
		return
	_checked = true
	_check_button.disabled = true
	_selected = -1
	_selection_label.text = "Checked. ✓ = correct; ✗ = review the correct bin shown."
	for index in range(CHIPS.size()):
		var chip: Dictionary = CHIPS[index]
		var correct: bool = int(_assignments.get(index, -1)) == int(chip["bin"])
		Progress.record_topic_only("hemo", correct)
		if correct:
			_correct += 1
		var button: Button = _buttons[index]
		button.disabled = true
		button.set_pressed_no_signal(false)
		button.text = ("✓ " if correct else "✗ ") + String(chip["name"])
		if not correct:
			button.text += "\nCorrect bin: " + String(BINS[int(chip["bin"])])
		button.add_theme_color_override("font_disabled_color", ThemeBuilder.SUCCESS if correct else ThemeBuilder.ERROR)
