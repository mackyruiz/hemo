extends Control

const CATEGORIES := {
	"rbc": "RBC morphology", "inclusion": "RBC inclusions", "organism": "Organisms",
	"wbc": "WBC", "plt": "Platelets", "stain": "Special stains",
}
var _list: VBoxContainer


func _ready() -> void:
	var page: Array = UI.page("Cell Atlas")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	var search := LineEdit.new()
	search.placeholder_text = "Search cells and findings"
	search.custom_minimum_size.y = 64
	search.text_changed.connect(_filter)
	content.add_child(search)
	_list = UI.vbox(12)
	content.add_child(_list)
	_filter("")


func _filter(text: String) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var needle: String = text.strip_edges().to_lower()
	var ids: Array = Content.morph.keys()
	ids.sort()
	var matches: int = 0
	for category in CATEGORIES:
		var heading_added: bool = false
		for value in ids:
			var id: String = str(value)
			var entity: Dictionary = Content.morph[id]
			var name_text: String = str(entity.get("name", id))
			if entity.get("category", "") != category or (not needle.is_empty() and not name_text.to_lower().contains(needle)):
				continue
			if not heading_added:
				_list.add_child(UI.label(CATEGORIES[category], "TitleLabel"))
				heading_added = true
			_list.add_child(_entry_row(id, entity))
			matches += 1
	if matches == 0:
		_list.add_child(UI.label("No matching cells or findings.", "MutedLabel"))


func _entry_row(id: String, entity: Dictionary) -> Button:
	var button := UI.button("", _open.bind(id), "SecondaryButton")
	button.custom_minimum_size.y = 116
	var row := UI.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_top = 10
	row.offset_right = -12
	row.offset_bottom = -10
	var preview := CenterContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(84, 84)
	var photos: Array = Content.photos_by_morph.get(id, [])
	if not photos.is_empty():
		preview.add_child(PhotoView.thumbnail(photos[0], 84.0))
	row.add_child(preview)
	var title := UI.label(str(entity.get("name", id)))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var arrow := UI.label("›")
	arrow.size_flags_horizontal = Control.SIZE_SHRINK_END
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(arrow)
	var fit_height := func():
		button.custom_minimum_size.y = maxf(116.0, row.get_combined_minimum_size().y + 20.0)
	row.minimum_size_changed.connect(fit_height)
	fit_height.call_deferred()
	return button


func _open(id: String) -> void:
	Nav.go("atlas_entry", {"id": id})
