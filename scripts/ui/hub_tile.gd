class_name HubTile
extends PanelContainer
## Large square home-screen tile: tinted panel, vector graphic, title, one-line description.


static func make(title: String, desc: String, art_kind: String, tint: Color, callback: Callable) -> HubTile:
	var tile := HubTile.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", ThemeBuilder._box(tint.lerp(ThemeBuilder.SURFACE, 0.86), 20, tint, 2, 14))
	var v := UI.vbox(4)
	tile.add_child(v)
	v.add_child(HubArt.make(art_kind, tint))
	var t := UI.label(title, "TitleLabel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", tint.darkened(0.15))
	v.add_child(t)
	var d := UI.label(desc, "MutedLabel")
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	UI.tappable(tile, callback)
	return tile


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not is_equal_approx(custom_minimum_size.y, size.x):
		custom_minimum_size.y = size.x
