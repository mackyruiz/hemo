class_name HubArt
extends Control
## Flat vector graphic for a hub feature tile, drawn inside a centered square.

const W := ThemeBuilder.SURFACE
const T := ThemeBuilder.TEXT
const M := ThemeBuilder.MUTED
const G := ThemeBuilder.SUCCESS
const CLEAR := Color(0, 0, 0, 0)
const CELLS := [["normal_rbc", 0.32, 0.36, 11], ["normal_rbc", 0.70, 0.24, 14], ["neutrophil_seg", 0.62, 0.60, 12], ["normal_platelet", 0.30, 0.70, 13]]

var kind: String = ""
var tint: Color = ThemeBuilder.PRIMARY


static func make(art_kind: String, art_tint: Color) -> HubArt:
	var art := HubArt.new()
	art.kind = art_kind
	art.tint = art_tint
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return art


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	if s < 8.0:
		return
	var o := Vector2((size.x - s) * 0.5, (size.y - s) * 0.5)
	match kind:
		"practice":
			_draw_practice(o, s)
		"board_sim":
			_draw_board_sim(o, s)
		"lab_floor":
			_draw_lab_floor(o, s)
		"atlas":
			_draw_atlas(o, s)
		"flashcards":
			_draw_flashcards(o, s)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


func _box(rect: Rect2, fill: Color, border: Color, border_w: int, radius: int) -> void:
	ThemeBuilder._box(fill, radius, border, border_w, 0).draw(get_canvas_item(), rect)


func _rounded(o: Vector2, s: float, x: float, y: float, w: float, h: float, fill: Color, border: Color, border_w: int) -> void:
	_box(Rect2(_p(o, s, x, y), Vector2(w * s, h * s)), fill, border, border_w, int(0.04 * s))


func _draw_practice(o: Vector2, s: float) -> void:
	var center := _p(o, s, 0.5, 0.52)
	for ring in [[0.40, tint], [0.30, W], [0.20, tint], [0.10, W]]:
		draw_circle(center, float(ring[0]) * s, ring[1] as Color)
	draw_line(_p(o, s, 0.86, 0.16), _p(o, s, 0.53, 0.49), T, 0.035 * s)
	draw_line(_p(o, s, 0.86, 0.16), _p(o, s, 0.93, 0.14), T, 0.03 * s)
	draw_line(_p(o, s, 0.86, 0.16), _p(o, s, 0.88, 0.09), T, 0.03 * s)


func _draw_board_sim(o: Vector2, s: float) -> void:
	_box(Rect2(_p(o, s, 0.18, 0.14), Vector2(0.46 * s, 0.66 * s)), W, tint, int(0.03 * s), int(0.04 * s))
	_box(Rect2(_p(o, s, 0.31, 0.08), Vector2(0.20 * s, 0.10 * s)), tint, CLEAR, 0, int(0.04 * s))
	for y in [0.32, 0.46, 0.60]:
		draw_polyline([_p(o, s, 0.25, y), _p(o, s, 0.28, y + 0.03), _p(o, s, 0.34, y - 0.03)], G, 0.025 * s)
		draw_line(_p(o, s, 0.38, y), _p(o, s, 0.56, y), M, 0.025 * s)
	var center := _p(o, s, 0.70, 0.70)
	draw_circle(center, 0.17 * s, W)
	draw_arc(center, 0.17 * s, 0.0, TAU, 48, tint, 0.03 * s)
	_box(Rect2(_p(o, s, 0.675, 0.49), Vector2(0.05 * s, 0.04 * s)), tint, CLEAR, 0, int(0.04 * s))
	draw_line(center, _p(o, s, 0.70, 0.59), T, 0.025 * s)
	draw_line(center, _p(o, s, 0.78, 0.70), T, 0.02 * s)


func _draw_lab_floor(o: Vector2, s: float) -> void:
	_box(Rect2(_p(o, s, 0.24, 0.80), Vector2(0.52 * s, 0.08 * s)), tint, CLEAR, 0, int(0.04 * s))
	var stem: Color = tint.darkened(0.2)
	draw_line(_p(o, s, 0.64, 0.80), _p(o, s, 0.64, 0.42), stem, 0.07 * s)
	draw_line(_p(o, s, 0.64, 0.42), _p(o, s, 0.50, 0.28), stem, 0.07 * s)
	_box(Rect2(_p(o, s, 0.28, 0.60), Vector2(0.40 * s, 0.04 * s)), M, CLEAR, 0, int(0.04 * s))
	draw_rect(Rect2(_p(o, s, 0.38, 0.575), Vector2(0.16 * s, 0.025 * s)), Color("#D98C8C"))
	draw_line(_p(o, s, 0.40, 0.20), _p(o, s, 0.48, 0.50), T, 0.09 * s)
	draw_line(_p(o, s, 0.36, 0.10), _p(o, s, 0.40, 0.21), T, 0.06 * s)
	draw_line(_p(o, s, 0.48, 0.50), _p(o, s, 0.49, 0.56), M, 0.05 * s)


func _draw_atlas(o: Vector2, s: float) -> void:
	var center := _p(o, s, 0.5, 0.5)
	draw_circle(center, 0.46 * s, W)
	draw_arc(center, 0.46 * s, 0.0, TAU, 64, tint, 0.02 * s)
	for cell in CELLS:
		var desc: Dictionary = Content.morph.get(cell[0], {}).get("art", {})
		if desc.is_empty():
			continue
		CellArt.draw_cell(self, desc, _p(o, s, cell[1], cell[2]), 0.30 * s, int(cell[3]))


func _draw_flashcards(o: Vector2, s: float) -> void:
	var w: float = 0.56 * s
	var h: float = 0.40 * s
	var card := Rect2(Vector2(-w / 2.0, -h / 2.0), Vector2(w, h))
	draw_set_transform(_p(o, s, 0.46, 0.46), -0.20, Vector2.ONE)
	_box(card, W, tint, int(0.025 * s), int(0.04 * s))
	draw_set_transform(_p(o, s, 0.54, 0.56), 0.10, Vector2.ONE)
	_box(card, tint, CLEAR, 0, int(0.04 * s))
	var fs: int = int(0.22 * s)
	draw_string(get_theme_default_font(), Vector2(-w / 2.0, fs * 0.35), "?", HORIZONTAL_ALIGNMENT_CENTER, w, fs, W)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
