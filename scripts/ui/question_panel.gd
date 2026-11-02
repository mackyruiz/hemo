class_name QuestionPanel
extends VBoxContainer
## Choices retain their original indices even though their display order is shuffled.

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
	add_child(UI.label(str(q.get("stem", ""))))
	var image_id: String = str(q.get("image", "")) if q.get("image") != null else ""
	if not image_id.is_empty():
		_add_image(image_id, str(opts.get("image_source", "art")))
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


func _add_image(morph_id: String, source: String) -> void:
	var available: Array = Content.photos_by_morph.get(morph_id, [])
	if source == "photo" and not available.is_empty():
		var photo: Dictionary = available[_rng.randi_range(0, available.size() - 1)]
		var texture: Texture2D = load(str(photo["file"])) as Texture2D
		if texture != null:
			var crop: Array = photo.get("crop", [0.0, 0.0, 1.0, 1.0])
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				float(crop[0]) * texture.get_width(), float(crop[1]) * texture.get_height(),
				float(crop[2]) * texture.get_width(), float(crop[3]) * texture.get_height()
			)
			var image := TextureRect.new()
			image.texture = atlas
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size.y = 320
			image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			add_child(image)
			var credit: String = "Photo: %s, %s" % [photo.get("author", ""), photo.get("license", "")]
			if crop != [0, 0, 1, 1]:
				credit += " (cropped)"
			add_child(UI.label(credit, "MutedLabel"))
			return
	var entity: Dictionary = Content.morph.get(morph_id, {})
	if entity.has("art"):
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var descriptor: Dictionary = entity["art"]
		var art_scale: float = minf(130.0, 220.0 / (2.0 * CellArt.cell_radius(descriptor, 1.0)))
		center.custom_minimum_size.y = 240
		center.add_child(CellArt.make(descriptor, hash(morph_id), art_scale))
		add_child(center)


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
