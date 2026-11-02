extends Control
## Shared sequential case presentation; coagulation cases use this with bench="coag".

signal finished(result: Dictionary)

var _task: Dictionary
var _case: Dictionary
var _content: VBoxContainer
var _step_host: VBoxContainer
var _panel: QuestionPanel
var _step_index: int = 0
var _correct: int = 0
var _completed: bool = false


func start(task: Dictionary) -> void:
	_task = task
	_case = Content.cases_by_id[String(task["case_id"])]
	_build()
	_show_step()


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	_content = UI.vbox(16)
	margin.add_child(_content)
	var kind: String = String(_task.get("bench", "cbc"))
	_content.add_child(UI.label("CBC review" if kind == "cbc" else "Coagulation review", "TitleLabel"))
	var vignette := UI.card()
	var text := UI.vbox()
	vignette.add_child(text)
	text.add_child(UI.label("Adult patient · Age %d · %s" % [int(_case["age"]), String(_case["sex"])], "MutedLabel"))
	text.add_child(UI.label(String(_case["vignette"])))
	_content.add_child(vignette)
	var results: Dictionary = _case["cbc"] if kind == "cbc" else _case["results"]
	_content.add_child(ReportTable.build(kind, results, String(_case["sex"])))
	if kind == "cbc":
		_add_smear()
	_step_host = UI.vbox(12)
	_content.add_child(_step_host)


func _add_smear() -> void:
	var smear: Array = _case.get("smear", [])
	if smear.is_empty():
		return
	_content.add_child(UI.label("Peripheral smear", "TitleLabel"))
	for raw_id in smear:
		var morph_id: String = String(raw_id)
		var entity: Dictionary = Content.morph[morph_id]
		var card := UI.card()
		var column := UI.vbox()
		card.add_child(column)
		column.add_child(UI.label(String(entity["name"])))
		var photos: Array = Content.photos_by_morph.get(morph_id, [])
		if int(_task.get("tier", 1)) >= 2 and not photos.is_empty():
			var photo: Dictionary = photos[0]
			var texture: Texture2D = load(String(photo["file"]))
			var crop: Array = photo.get("crop", [0.0, 0.0, 1.0, 1.0])
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(crop[0]) * texture.get_width(), float(crop[1]) * texture.get_height(), float(crop[2]) * texture.get_width(), float(crop[3]) * texture.get_height())
			var image := TextureRect.new()
			image.texture = atlas
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size.y = 240
			column.add_child(image)
			var crop_notice: String = " (cropped)" if crop != [0.0, 0.0, 1.0, 1.0] else ""
			column.add_child(UI.label("Photo: %s, %s%s" % [String(photo["author"]), String(photo["license"]), crop_notice], "MutedLabel"))
			column.add_child(UI.label(CellArt.PHOTO_SCALE_NOTE, "MutedLabel"))
		else:
			column.add_child(CellArt.make(entity["art"], int(morph_id.hash()), 110.0, true))
			column.add_child(UI.label("Illustration", "MutedLabel"))
		_content.add_child(card)


func _show_step() -> void:
	if _panel != null:
		_step_host.remove_child(_panel)
		_panel.queue_free()
	var steps: Array = _case["steps"]
	if _step_index >= steps.size():
		_complete()
		return
	var question: Dictionary = steps[_step_index].duplicate(true)
	question["stem"] = "Step %d/%d\n%s" % [_step_index + 1, steps.size(), String(question["stem"])]
	question["source"] = String(question.get("source", _case.get("source", "")))
	_panel = QuestionPanel.new()
	_step_host.add_child(_panel)
	_panel.answered.connect(_on_answered)
	_panel.next_pressed.connect(_on_next)
	_panel.setup(question, {"show_feedback": true, "image_source": "art", "flag": {"key": "%s#%d" % [String(_case["id"]), _step_index + 1], "case_id": String(_case["id"])}})


func _on_answered(correct: bool, _chosen_index: int) -> void:
	if correct:
		_correct += 1


func _on_next() -> void:
	_step_index += 1
	_show_step()


func _complete() -> void:
	if _completed:
		return
	_completed = true
	var total: int = _case["steps"].size()
	Progress.record_item(String(_case["id"]), String(_case["topic"]), _correct == total)
	finished.emit({"correct": _correct, "total": total, "xp": _correct * XpRules.XP_CASE_STEP})
