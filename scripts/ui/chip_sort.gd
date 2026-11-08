class_name ChipSort
extends Control
## Tap-to-sort control: unsorted items sit in one scrolling tray; the containers are
## tinted targets pinned in a dock at the bottom. Check marks each item.

## One entry per chip index, true when the chip sits in its correct bin.
signal checked(results: Array[bool])

## Content column, so hosts can append buttons after checking.
var column: VBoxContainer

var _bins: Array = []
var _chips: Array = []
var _source_id: String = ""
var _item_noun: String = "item"
var _bin_noun: String = "container"
var _buttons: Array[Button] = []
var _tray: VBoxContainer
var _tray_card: PanelContainer
var _tray_header: Label
var _bin_cards: Array[PanelContainer] = []
var _bin_headers: Array[Label] = []
var _bin_hosts: Array[VBoxContainer] = []
var _dock: PanelContainer
var _dock_buttons: Array[Button] = []
var _banner: Label
var _summary: Label
var _check_button: Button
var _assignments: Dictionary = {}
var _selected: int = -1
var _checked: bool = false


## Chips are {"name": String, "bin": int}; the tray order is shuffled with rng.
## item_noun/bin_noun keep the wording matched to the host bench (item/container,
## factor/pathway, ...).
func setup(title: String, instructions: String, bins: Array, chips: Array, rng: RandomNumberGenerator, source_id: String, item_noun: String = "item", bin_noun: String = "container") -> void:
	_bins = bins
	_chips = chips
	_source_id = source_id
	_item_noun = item_noun
	_bin_noun = bin_noun

	var shell := VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	column = UI.vbox(16)
	margin.add_child(column)
	column.add_child(UI.label(title, "TitleLabel"))
	column.add_child(UI.label(instructions))
	_summary = UI.label("", "MutedLabel")
	_summary.visible = false
	column.add_child(_summary)

	_tray_card = UI.card()
	_tray_card.add_theme_stylebox_override("panel", ThemeBuilder._box(ThemeBuilder.SURFACE, 14, ThemeBuilder.CHIP_BORDER, 2, 16))
	column.add_child(_tray_card)
	var tray_column := UI.vbox(8)
	_tray_card.add_child(tray_column)
	_tray_header = UI.label("", "MutedLabel")
	tray_column.add_child(_tray_header)
	_tray = UI.vbox(8)
	tray_column.add_child(_tray)

	for index in range(_chips.size()):
		var chip: Dictionary = _chips[index]
		var button := UI.button(String(chip["name"]), _select_chip.bind(index), "ChipButton")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_buttons.append(button)
	# Shuffle the tray order, remembering each button's slot so a picked-up item returns
	# to the same place rather than to the end of the list.
	var order: Array[int] = []
	for index in range(_chips.size()):
		order.append(index)
	for index in range(order.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, index)
		var old: int = order[index]
		order[index] = order[swap]
		order[swap] = old
	for position in range(order.size()):
		var button: Button = _buttons[order[position]]
		button.set_meta("rank", position)
		_tray.add_child(button)

	for index in range(_bins.size()):
		var tint: Color = ThemeBuilder.sort_tint(index)
		var card := UI.card()
		card.add_theme_stylebox_override("panel", ThemeBuilder._box(tint.lerp(ThemeBuilder.SURFACE, 0.93), 14, tint, 2, 16))
		var bin_column := UI.vbox(8)
		card.add_child(bin_column)
		var header := UI.label("", "MutedLabel")
		header.add_theme_color_override("font_color", tint.darkened(0.15))
		bin_column.add_child(header)
		var host := UI.vbox(8)
		bin_column.add_child(host)
		_bin_cards.append(card)
		_bin_headers.append(header)
		_bin_hosts.append(host)
		column.add_child(card)

	_dock = PanelContainer.new()
	var rule := ThemeBuilder._box(ThemeBuilder.SURFACE, 0, Color("#D9D2CC"), 0, 0)
	rule.set_border_width(SIDE_TOP, 2)
	_dock.add_theme_stylebox_override("panel", rule)
	shell.add_child(_dock)
	var dock_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		dock_margin.add_theme_constant_override("margin_" + side, 12)
	_dock.add_child(dock_margin)
	var dock_column := UI.vbox(8)
	dock_margin.add_child(dock_column)
	_banner = UI.label("")
	dock_column.add_child(_banner)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	dock_column.add_child(grid)
	for index in range(_bins.size()):
		var bin_button := UI.button("", _place_chip.bind(index), "BinButton")
		bin_button.custom_minimum_size = Vector2(0, 76)
		bin_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_dock_buttons.append(bin_button)
		grid.add_child(bin_button)
	_check_button = UI.button("", _check)
	dock_column.add_child(_check_button)
	_refresh_chips()
	_refresh_groups()


## Picks up the held item, puts the held item down, or picks a placed item back up.
func _select_chip(index: int) -> void:
	if _checked:
		return
	if _selected == index:
		_selected = -1
	else:
		_selected = index
		if _assignments.has(index):
			_assignments.erase(index)
			_return_to_tray(index)
	_refresh_chips()
	_refresh_groups()


func _place_chip(bin_index: int) -> void:
	if _checked:
		return
	if _selected < 0:
		_banner.text = "Tap an %s in the list first." % _item_noun
		_banner.add_theme_color_override("font_color", ThemeBuilder.ERROR)
		return
	_buttons[_selected].reparent(_bin_hosts[bin_index])
	_assignments[_selected] = bin_index
	_selected = -1
	_refresh_chips()
	_refresh_groups()


## Puts a picked-up item back in its original shuffled slot instead of the list end.
func _return_to_tray(index: int) -> void:
	var button: Button = _buttons[index]
	button.reparent(_tray)
	var rank: int = int(button.get_meta("rank"))
	var pos := 0
	for child in _tray.get_children():
		if child == button:
			continue
		if int(child.get_meta("rank")) < rank:
			pos += 1
	_tray.move_child(button, pos)


func _refresh_chips() -> void:
	if _checked:
		return
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		var name: String = String(_chips[index]["name"])
		if index == _selected:
			# Dark ink for the held item, so "held" can never read as a container tint.
			ThemeBuilder.tint_button(button, ThemeBuilder.TEXT, Color.WHITE, ThemeBuilder.TEXT, 2)
			button.text = "▸ " + name
		elif _assignments.has(index):
			var tint: Color = ThemeBuilder.sort_tint(int(_assignments[index]))
			ThemeBuilder.tint_button(button, tint.lerp(ThemeBuilder.SURFACE, 0.90), ThemeBuilder.TEXT, tint, 2)
			button.text = ThemeBuilder.sort_glyph(int(_assignments[index])) + " " + name
		else:
			ThemeBuilder.clear_button_tint(button)
			button.text = name


func _refresh_groups() -> void:
	var left := _tray.get_child_count()
	# After checking, nothing can be moved, so the header counts what was never placed.
	var left_word: String = "unplaced" if _checked else "to sort"
	_tray_header.text = "%d %s left %s" % [left, _item_noun if left == 1 else _item_noun + "s", left_word]
	_tray_card.visible = left > 0
	var placed := 0
	for index in range(_bins.size()):
		var count := _bin_hosts[index].get_child_count()
		placed += count
		var tint: Color = ThemeBuilder.sort_tint(index)
		_bin_headers[index].text = "%s %s — %d placed" % [ThemeBuilder.sort_glyph(index), String(_bins[index]), count]
		_bin_cards[index].visible = count > 0
		if _dock == null:
			continue
		var bin_button: Button = _dock_buttons[index]
		bin_button.text = "%s %s" % [ThemeBuilder.sort_glyph(index), String(_bins[index])]
		if count > 0:
			bin_button.text += "\n%d placed" % count
		# An armed pick deepens the target tint so the tap is obviously doing something.
		if _selected >= 0:
			ThemeBuilder.tint_button(bin_button, tint.lerp(ThemeBuilder.SURFACE, 0.70), tint.darkened(0.30), tint, 3)
		else:
			ThemeBuilder.tint_button(bin_button, tint.lerp(ThemeBuilder.SURFACE, 0.90), tint.darkened(0.15), tint, 2)
	# The dock carries the banner and Check button; once it is freed there is nothing to update.
	if _dock != null:
		_check_button.text = "Check — %d of %d placed" % [placed, _chips.size()]
		if _selected >= 0:
			_banner.text = "Holding: %s — tap a %s below." % [String(_chips[_selected]["name"]), _bin_noun]
		else:
			_banner.text = "Tap an %s, then tap the %s it belongs in." % [_item_noun, _bin_noun]
		_banner.remove_theme_color_override("font_color")


func _check() -> void:
	if _checked:
		return
	_checked = true
	_selected = -1
	# The dock's job is over; free it so the results list and the host's Next button get
	# the full height.
	if _dock != null:
		_dock.queue_free()
		_dock = null
	var results: Array[bool] = []
	var correct_count := 0
	for index in range(_chips.size()):
		var chip: Dictionary = _chips[index]
		var correct: bool = int(_assignments.get(index, -1)) == int(chip["bin"])
		results.append(correct)
		if correct:
			correct_count += 1
		var button: Button = _buttons[index]
		button.disabled = true
		if correct:
			ThemeBuilder.tint_button(button, ThemeBuilder.SUCCESS_BG, ThemeBuilder.SUCCESS.darkened(0.15), ThemeBuilder.SUCCESS, 2)
			button.text = "✓ " + String(chip["name"])
		else:
			ThemeBuilder.tint_button(button, ThemeBuilder.ERROR_BG, ThemeBuilder.ERROR.darkened(0.10), ThemeBuilder.ERROR, 2)
			button.text = "✗ " + String(chip["name"]) + "\nCorrect %s: %s %s" % [_bin_noun, ThemeBuilder.sort_glyph(int(chip["bin"])), String(_bins[int(chip["bin"])])]
	_summary.text = "Checked: %d of %d correct. ✓ correct; ✗ shows the right %s." % [correct_count, _chips.size(), _bin_noun]
	_summary.visible = true
	var link: Button = UI.source_link(_source_id)
	if link != null:
		column.add_child(link)
	_refresh_groups()
	checked.emit(results)
