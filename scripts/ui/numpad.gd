class_name NumPad
extends VBoxContainer
## Touch-friendly numeric entry without opening a mobile browser keyboard.

signal submitted(value: float)

var _entered: String = ""
var _display: Label
var _submit: Button


func _ready() -> void:
	_build()


func clear() -> void:
	_entered = ""
	_build()
	_refresh()


func _build() -> void:
	if _display != null:
		return
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	var display_card: PanelContainer = UI.card()
	_display = UI.label(" ")
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_display.custom_minimum_size.y = 48
	display_card.add_child(_display)
	add_child(display_card)
	var keys := GridContainer.new()
	keys.columns = 3
	keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keys.add_theme_constant_override("h_separation", 12)
	keys.add_theme_constant_override("v_separation", 12)
	add_child(keys)
	for key in ["7", "8", "9", "4", "5", "6", "1", "2", "3", ".", "0", "⌫"]:
		var button: Button = UI.button(key, _press.bind(key), "SecondaryButton")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 72
		keys.add_child(button)
	_submit = UI.button("Submit", _submit_value)
	_submit.custom_minimum_size.y = 72
	add_child(_submit)
	_refresh()


func _press(key: String) -> void:
	if key == "⌫":
		_entered = _entered.left(maxi(0, _entered.length() - 1))
	elif key == ".":
		if not _entered.contains("."):
			_entered += "0." if _entered.is_empty() else "."
	else:
		_entered += key
	_refresh()


func _refresh() -> void:
	_display.text = _entered if not _entered.is_empty() else " "
	_submit.disabled = not _entered.is_valid_float()


func _submit_value() -> void:
	if _entered.is_valid_float():
		submitted.emit(_entered.to_float())
