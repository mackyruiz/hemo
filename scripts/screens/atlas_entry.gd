extends Control

var _id: String = ""
var _photos: Array = []
var _photo_index: int = 0
var _photo_view: TextureRect
var _credit: Label
var _photo_counter: Label


func setup(params: Dictionary) -> void:
	_id = str(params.get("id", ""))


func _ready() -> void:
	var entity: Dictionary = Content.morph.get(_id, {})
	var page: Array = UI.page(str(entity.get("name", "Atlas entry")))
	add_child(page[0])
	var content: VBoxContainer = page[1]
	if entity.is_empty():
		content.add_child(UI.label("This atlas entry is not available."))
		return
	content.add_child(UI.label("Illustration", "MutedLabel"))
	var illustration := CenterContainer.new()
	illustration.custom_minimum_size.y = 250
	var descriptor: Dictionary = entity.get("art", {})
	var art_scale: float = minf(130.0, 220.0 / (2.0 * CellArt.cell_radius(descriptor, 1.0)))
	var art: CellArt = CellArt.make(descriptor, 0, art_scale)
	illustration.add_child(art)
	content.add_child(illustration)

	_photos = Content.photos_by_morph.get(_id, [])
	if not _photos.is_empty():
		content.add_child(UI.label("Photomicrographs", "TitleLabel"))
		_photo_view = TextureRect.new()
		_photo_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_photo_view.custom_minimum_size.y = 340
		_photo_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_photo_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_photo_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(_photo_view)
		_credit = UI.label("", "MutedLabel")
		content.add_child(_credit)
		var controls := UI.hbox()
		if _photos.size() > 1:
			var previous: Button = UI.button("‹ Previous", func(): _show_photo(_photo_index - 1), "SecondaryButton")
			previous.custom_minimum_size.x = 200
			controls.add_child(previous)
		_photo_counter = UI.label("")
		_photo_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_photo_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		controls.add_child(_photo_counter)
		if _photos.size() > 1:
			var next: Button = UI.button("Next ›", func(): _show_photo(_photo_index + 1), "SecondaryButton")
			next.custom_minimum_size.x = 200
			controls.add_child(next)
		content.add_child(controls)
		_show_photo(0)
	else:
		content.add_child(UI.label("Illustration-only entry.", "MutedLabel"))

	content.add_child(UI.label("Features", "TitleLabel"))
	content.add_child(UI.label(str(entity.get("features", ""))))
	content.add_child(UI.label("Associations", "TitleLabel"))
	var associations: Array = entity.get("associations", [])
	for association in associations:
		content.add_child(UI.label("• " + str(association)))
	content.add_child(UI.label("Commonly confused with", "TitleLabel"))
	var confusers: Array = entity.get("confusers", [])
	for value in confusers:
		var id: String = str(value)
		content.add_child(UI.button(Content.morph_name(id), _open_confuser.bind(id), "SecondaryButton"))


func _show_photo(index: int) -> void:
	_photo_index = posmod(index, _photos.size())
	var photo: Dictionary = _photos[_photo_index]
	var texture: Texture2D = load(str(photo["file"])) as Texture2D
	var crop: Array = photo.get("crop", [0, 0, 1, 1])
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(
		float(crop[0]) * texture.get_width(), float(crop[1]) * texture.get_height(),
		float(crop[2]) * texture.get_width(), float(crop[3]) * texture.get_height()
	)
	_photo_view.texture = atlas
	_credit.text = "Photo: %s, %s" % [photo.get("author", ""), photo.get("license", "")]
	if crop != [0, 0, 1, 1]:
		_credit.text += " (cropped)"
	_photo_counter.text = "%d / %d" % [_photo_index + 1, _photos.size()]


func _open_confuser(id: String) -> void:
	Nav.go("atlas_entry", {"id": id})
