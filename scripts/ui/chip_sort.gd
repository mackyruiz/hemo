class_name ChipSort
extends ScrollContainer
## Tap-to-sort control: tap a chip, then tap a bin; Check marks each chip.

## One entry per chip index, true when the chip sits in its correct bin.
signal checked(results: Array[bool])

## Content column, so hosts can append buttons after checking.
var column: VBoxContainer

var _bins: Array = []
var _chips: Array = []
var _source_id: String = ""
var _buttons: Array[Button] = []
var _bin_hosts: Array[VBoxContainer] = []
var _assignments: Dictionary = {}
var _selected: int = -1
var _selection_label: Label
var _check_button: Button
var _checked: bool = false


## Chips are {"name": String, "bin": int}; the pool is shuffled with rng.
func setup(title: String, instructions: String, bins: Array, chips: Array, rng: RandomNumberGenerator, source_id: String) -> void:
	_bins = bins
	_chips = chips
	_source_id = source_id
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	column = UI.vbox(16)
	margin.add_child(column)
	column.add_child(UI.label(title, "TitleLabel"))
	column.add_child(UI.label(instructions))
	_selection_label = UI.label("No chip selected", "MutedLabel")
	column.add_child(_selection_label)
	var pool := UI.vbox(8)
	column.add_child(pool)
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for index in range(_chips.size()):
		var chip: Dictionary = _chips[index]
		var button := UI.button(String(chip["name"]), _select_chip.bind(index), "SecondaryButton")
		button.toggle_mode = true
		button.button_group = group
		_buttons.append(button)
	var order: Array[int] = []
	for index in range(_chips.size()):
		order.append(index)
	for index in range(order.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, index)
		var old: int = order[index]
		order[index] = order[swap]
		order[swap] = old
	for index in order:
		pool.add_child(_buttons[index])
	for index in range(_bins.size()):
		var card := UI.card()
		var bin_column := UI.vbox(8)
		card.add_child(bin_column)
		bin_column.add_child(UI.button(String(_bins[index]) + "\nTap to place selected chip", _place_chip.bind(index), "SecondaryButton"))
		var host := UI.vbox(8)
		bin_column.add_child(host)
		_bin_hosts.append(host)
		column.add_child(card)
	_check_button = UI.button("Check", _check)
	column.add_child(_check_button)


func _select_chip(index: int) -> void:
	if _checked:
		return
	_selected = index if _buttons[index].button_pressed else -1
	_selection_label.text = "Selected: %s" % String(_chips[index]["name"]) if _selected >= 0 else "No chip selected"


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
	var results: Array[bool] = []
	for index in range(_chips.size()):
		var chip: Dictionary = _chips[index]
		var correct: bool = int(_assignments.get(index, -1)) == int(chip["bin"])
		results.append(correct)
		var button: Button = _buttons[index]
		button.disabled = true
		button.set_pressed_no_signal(false)
		button.text = ("✓ " if correct else "✗ ") + String(chip["name"])
		if not correct:
			button.text += "\nCorrect bin: " + String(_bins[int(chip["bin"])])
		button.add_theme_color_override("font_disabled_color", ThemeBuilder.SUCCESS if correct else ThemeBuilder.ERROR)
	var link: Button = UI.source_link(_source_id)
	if link != null:
		column.add_child(link)
	checked.emit(results)
