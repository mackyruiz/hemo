extends Control


func _ready() -> void:
	var page: Array = UI.page("Credits & licenses")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("Photomicrographs", "TitleLabel"))
	content.add_child(UI.label("Original sources and license terms are linked for every photo used in the app.", "MutedLabel"))
	if Content.photos.is_empty():
		content.add_child(UI.label("No photos are installed.", "MutedLabel"))
	for value in Content.photos:
		var photo: Dictionary = value
		var card := UI.card()
		var v := UI.vbox(8)
		card.add_child(v)
		v.add_child(UI.label(str(photo.get("source_title", photo.get("id", "Photo")))))
		v.add_child(UI.label("Author: " + str(photo.get("author", "")), "MutedLabel"))
		v.add_child(UI.label("License: " + str(photo.get("license", "")), "MutedLabel"))
		var crop: Array = photo.get("crop", [0, 0, 1, 1])
		if crop != [0, 0, 1, 1]:
			v.add_child(UI.label("Cropped for display", "MutedLabel"))
		v.add_child(UI.button("View source", _open_url.bind(str(photo.get("source_url", ""))), "SecondaryButton"))
		v.add_child(UI.button("View license", _open_url.bind(str(photo.get("license_url", ""))), "SecondaryButton"))
		content.add_child(card)
	content.add_child(UI.label("Godot Engine", "TitleLabel"))
	content.add_child(UI.label("HemoShift is built with Godot Engine, licensed under the MIT license.", "MutedLabel"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 360
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var license_text := UI.label(Engine.get_license_text())
	license_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(license_text)
	content.add_child(scroll)
	content.add_child(UI.label("DejaVu Sans", "TitleLabel"))
	content.add_child(UI.label(FileAccess.get_file_as_string("res://assets/fonts/LICENSE.txt")))
	content.add_child(UI.label("Lab Floor art", "TitleLabel"))
	content.add_child(UI.label(FileAccess.get_file_as_string("res://assets/lab/LICENSE.txt")))


func _open_url(url: String) -> void:
	if not url.is_empty():
		OS.shell_open(url)
