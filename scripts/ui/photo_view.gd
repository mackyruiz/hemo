class_name PhotoView
extends Control
## Photomicrograph renderer with a ring-and-arrow indicator for the finding in question.

const SCALE_NOTE := "Photos are not to scale — compare with a nearby normal RBC (≈7.5 µm)."
const MARKER_NOTE := "The circled cell or area is the finding in question."
const RING := Color("#FFD400")
const OUTLINE := Color.BLACK
const ARROW_LEN := 36.0
const ARROW_GAP := 4.0
const HEAD_LEN := 12.0
const HEAD_ANGLE := 2.6

var _texture: Texture2D
var _region: Rect2
var _markers: Array = []
var _show_markers: bool = true


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_photo(photo: Dictionary) -> void:
	_texture = load(str(photo["file"])) as Texture2D
	_markers = []
	if _texture == null:
		queue_redraw()
		return
	var W: float = float(_texture.get_width())
	var H: float = float(_texture.get_height())
	var crop: Array = photo.get("crop", [0.0, 0.0, 1.0, 1.0])
	_region = Rect2(float(crop[0]) * W, float(crop[1]) * H, float(crop[2]) * W, float(crop[3]) * H)
	for marker in photo.get("markers", []):
		_markers.append([Vector2(float(marker[0]) * W, float(marker[1]) * H), float(marker[2]) * W])
	queue_redraw()


static func make(photo: Dictionary, height: float) -> PhotoView:
	var view := PhotoView.new()
	view.set_photo(photo)
	view.custom_minimum_size = Vector2(minf(height * view._region.size.x / view._region.size.y, 640.0), height)
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return view


static func thumbnail(photo: Dictionary, side: float) -> PhotoView:
	var view := make(photo, side)
	view._show_markers = false
	view.custom_minimum_size = Vector2(side, side)
	if view._markers.is_empty() or view._texture == null:
		return view
	var W: float = float(view._texture.get_width())
	var H: float = float(view._texture.get_height())
	var n: float = minf(2.2 * float(view._markers[0][1]), minf(W, H))
	var center: Vector2 = view._markers[0][0]
	var origin := center - Vector2.ONE * n * 0.5
	origin.x = clampf(origin.x, 0.0, W - n)
	origin.y = clampf(origin.y, 0.0, H - n)
	view._region = Rect2(origin, Vector2(n, n))
	view.queue_redraw()
	return view


func _draw() -> void:
	if _texture == null or _region.size.x <= 0.0 or _region.size.y <= 0.0:
		return
	var s: float = minf(size.x / _region.size.x, size.y / _region.size.y)
	var dest := Rect2((size - _region.size * s) * 0.5, _region.size * s)
	draw_texture_rect_region(_texture, dest, _region)
	if not _show_markers:
		return
	for marker in _markers:
		var center: Vector2 = marker[0]
		var radius: float = float(marker[1])
		var p := dest.position + (center - _region.position) * s
		var pr: float = radius * s
		draw_arc(p, pr, 0.0, TAU, 64, OUTLINE, 5.0, true)
		draw_arc(p, pr, 0.0, TAU, 64, RING, 3.0, true)
		var u: Vector2 = Vector2(1, 1).normalized()
		var dirs: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
		for d in dirs:
			var du: Vector2 = d.normalized()
			if dest.has_point(p + du * (pr + ARROW_GAP + ARROW_LEN)):
				u = du
				break
		var tip: Vector2 = p + u * (pr + ARROW_GAP)
		var tail: Vector2 = tip + u * ARROW_LEN
		draw_line(tail, tip, OUTLINE, 6.0, true)
		draw_line(tail, tip, RING, 3.0, true)
		var head := PackedVector2Array([tip, tip + (-u).rotated(HEAD_ANGLE) * HEAD_LEN, tip + (-u).rotated(-HEAD_ANGLE) * HEAD_LEN])
		draw_colored_polygon(head, RING)
		head.append(tip)
		draw_polyline(head, OUTLINE, 1.5)


static func credit(photo: Dictionary) -> String:
	var crop: Array = photo.get("crop", [0.0, 0.0, 1.0, 1.0])
	var full: Array = [0.0, 0.0, 1.0, 1.0]
	for i in range(4):
		if not is_equal_approx(float(crop[i]), float(full[i])):
			return "Photo: %s, %s (cropped)" % [photo.get("author", ""), photo.get("license", "")]
	return "Photo: %s, %s" % [photo.get("author", ""), photo.get("license", "")]


static func block(photo: Dictionary, height: float) -> VBoxContainer:
	var column := UI.vbox(6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(make(photo, height))
	column.add_child(UI.label(MARKER_NOTE, "MutedLabel"))
	column.add_child(UI.label(credit(photo), "MutedLabel"))
	column.add_child(UI.label(SCALE_NOTE, "MutedLabel"))
	return column
