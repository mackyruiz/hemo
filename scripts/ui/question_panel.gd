class_name QuestionPanel
extends VBoxContainer
## Choices retain their original indices even though their display order is shuffled.
const FLAG_OFF := "Flag for review"
const FLAG_ON := "Flagged for review — tap to remove"

var _flag_key: String = ""
var _flag_button: Button = null
var _opts: Dictionary = {}

signal answered(correct: bool, chosen_index: int)
signal next_pressed

var _question: Dictionary = {}
var _show_feedback: bool = true
var _answered: bool = false
var _mapping: Array[int] = []
var _buttons: Array[Button] = []
var _rng: RandomNumberGenerator
var _hint_button: Button
var _hinted: bool = false


func setup(q: Dictionary, opts: Dictionary = {}) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_question = q
	_show_feedback = bool(opts.get("show_feedback", true))
	_answered = false
	_hinted = false
	_hint_button = null
	_mapping.clear()
	_buttons.clear()
	_rng = opts.get("rng") as RandomNumberGenerator
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	_opts = opts
	var flag_opt: Variant = opts.get("flag", {})
	_flag_key = ""
	if flag_opt is Dictionary:
		_flag_key = str(flag_opt.get("key", ""))
	if not _flag_key.is_empty():
		_flag_button = UI.button(FLAG_ON if Progress.is_flagged(_flag_key) else FLAG_OFF, _toggle_flag, "SecondaryButton")
		add_child(_flag_button)
	add_child(UI.label(str(q.get("stem", ""))))
	var image_id: String = str(q.get("image", "")) if q.get("image") != null else ""
	if not image_id.is_empty():
		_add_image(image_id)
	var choices: Array = q.get("choices", [])
	for i in range(choices.size()):
		_mapping.append(i)
	for i in range(_mapping.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: int = _mapping[i]
		_mapping[i] = _mapping[j]
		_mapping[j] = swap
	for original_index in _mapping:
		var button: Button = UI.button(str(choices[original_index]), _choose.bind(original_index), "SecondaryButton")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 72
		add_child(button)
		_buttons.append(button)
	if bool(opts.get("allow_hint", true)) and _show_feedback and choices.size() >= Hint.MIN_CHOICES:
		_hint_button = UI.button("Hint: remove two wrong answers", _use_hint, "SecondaryButton")
		add_child(_hint_button)


func _use_hint() -> void:
	if _answered or _hinted:
		return
	_hinted = true
	var removed: Array[int] = Hint.eliminate(_buttons.size(), int(_question.get("answer", -1)), _rng)
	for i in range(_buttons.size()):
		if _mapping[i] in removed:
			_buttons[i].disabled = true
			_buttons[i].modulate.a = 0.4
			_buttons[i].text = "(removed) " + _buttons[i].text
	_hint_button.disabled = true
	_hint_button.text = "Hint used: two wrong answers removed"


func _add_image(morph_id: String) -> void:
	var available: Array = Content.photos_by_morph.get(morph_id, [])
	if available.is_empty():
		return
	var photo: Dictionary = available[_rng.randi_range(0, available.size() - 1)]
	add_child(PhotoView.block(photo, 320))


func _choose(chosen_index: int) -> void:
	if _answered:
		return
	_answered = true
	if _hint_button != null:
		_hint_button.queue_free()
		_hint_button = null
	var correct_index: int = int(_question.get("answer", -1))
	var correct: bool = chosen_index == correct_index
	for button in _buttons:
		button.disabled = true
	if _show_feedback:
		for i in range(_buttons.size()):
			var original_index: int = _mapping[i]
			var button: Button = _buttons[i]
			if original_index == correct_index:
				button.text = "✓ " + button.text
				button.add_theme_color_override("font_disabled_color", ThemeBuilder.SUCCESS)
			elif original_index == chosen_index:
				button.text = "✗ " + button.text
				button.add_theme_color_override("font_disabled_color", ThemeBuilder.ERROR)
		var status: Label = UI.label("✓ Correct" if correct else "✗ Incorrect")
		status.add_theme_color_override("font_color", ThemeBuilder.SUCCESS if correct else ThemeBuilder.ERROR)
		add_child(status)
		var explanation: PanelContainer = UI.card()
		explanation.add_child(UI.label(str(_question.get("explanation", ""))))
		add_child(explanation)
		var link: Button = UI.source_link(str(_question.get("source", "")))
		if link != null:
			add_child(link)
		add_child(UI.button("Next", func(): next_pressed.emit()))
	answered.emit(correct, chosen_index)


func _toggle_flag() -> void:
	if _flag_key.is_empty():
		return
	if Progress.is_flagged(_flag_key):
		Progress.unflag(_flag_key)
	else:
		Progress.flag(_flag_key, _snapshot())
	if _flag_button != null:
		_flag_button.text = FLAG_ON if Progress.is_flagged(_flag_key) else FLAG_OFF


func _snapshot() -> Dictionary:
	var flag_opt: Variant = _opts.get("flag", {})
	var case_id: String = ""
	if flag_opt is Dictionary:
		case_id = str(flag_opt.get("case_id", ""))
	return {
		"stem": str(_question.get("stem", "")),
		"image": str(_question.get("image", "")),
		"choices": _question.get("choices", []).duplicate(true),
		"answer": int(_question.get("answer", -1)),
		"explanation": str(_question.get("explanation", "")),
		"source": str(_question.get("source", "")),
		"topic": str(_question.get("topic", "")),
		"case_id": case_id,
	}
