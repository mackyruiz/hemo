class_name ScenarioArt
extends Control
## Flat vector illustration of one lab incident, drawn inside a centred 3:2 box.
## Recipe coordinates are normalized: x runs 0..1.5, y runs 0..1, both scaled by s.
## Materials reuse the SortArt palette so a bottle looks the same here as on a chip.

const KINDS := ["mercury_spill", "chem_spill", "water_leak", "needlestick", "centrifuge_break", "eye_splash", "bench_fire"]

const ASPECT := 1.5
const WALL := Color("#EFEAE6")
const FLOOR := Color("#DED6CE")
const COUNTER := Color("#C9BCAE")
const WATER := Color("#9EC6DE")
const FLAME := Color("#E0762A")
const FLAME_CORE := Color("#F2C14B")
const INK := ThemeBuilder.TEXT
const CLEAR := SortArt.CLEAR

var kind: String = ""
var painted: bool = false                ## false after a draw pass with no recipe for kind


static func make(art_kind: String) -> ScenarioArt:
	var art := ScenarioArt.new()
	art.kind = art_kind
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(0, 180)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return art


static func has_kind(art_kind: String) -> bool:
	return KINDS.has(art_kind)


func _ready() -> void:
	resized.connect(_fit)
	_fit()


## The scene needs width to read, so the box takes the full card width and asks for the
## matching 3:2 height rather than sitting small in the middle of a wide card.
func _fit() -> void:
	var wanted: float = size.x / ASPECT
	if not is_equal_approx(custom_minimum_size.y, wanted):
		custom_minimum_size.y = wanted
	queue_redraw()


func _draw() -> void:
	painted = false
	var s: float = minf(size.x / ASPECT, size.y)
	if s < 16.0:
		return
	painted = _paint(Vector2((size.x - s * ASPECT) * 0.5, (size.y - s) * 0.5), s)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


func _rect(o: Vector2, s: float, x: float, y: float, w: float, h: float, fill: Color, border: Color, border_w: float, radius: float = 0.05) -> void:
	ThemeBuilder._box(fill, int(radius * s), border, int(maxf(border_w * s, 1.0)), 0).draw(get_canvas_item(), Rect2(_p(o, s, x, y), Vector2(w * s, h * s)))


func _poly(o: Vector2, s: float, points: Array, fill: Color, outline: Color = CLEAR, outline_w: float = 0.012) -> void:
	var loop := PackedVector2Array()
	for point: Vector2 in points:
		loop.append(o + point * s)
	draw_colored_polygon(loop, fill)
	if outline.a > 0.0:
		loop.append(loop[0])
		draw_polyline(loop, outline, outline_w * s)


func _ln(o: Vector2, s: float, x1: float, y1: float, x2: float, y2: float, colour: Color, w: float) -> void:
	draw_line(_p(o, s, x1, y1), _p(o, s, x2, y2), colour, w * s)


## An open stroke through the listed points: pipes, water jets, vapour, hoses.
func _stroke(o: Vector2, s: float, points: Array, colour: Color, w: float) -> void:
	var line := PackedVector2Array()
	for point: Vector2 in points:
		line.append(o + point * s)
	draw_polyline(line, colour, w * s)


## Wall above, floor below the horizon, with a thin skirting line.
func _room(o: Vector2, s: float, horizon: float) -> void:
	_rect(o, s, 0.0, 0.0, ASPECT, horizon, WALL, CLEAR, 0.0, 0.0)
	_rect(o, s, 0.0, horizon, ASPECT, 1.0 - horizon, FLOOR, CLEAR, 0.0, 0.0)
	_ln(o, s, 0.0, horizon, ASPECT, horizon, ThemeBuilder.MUTED, 0.008)


## A bench: cabinet body standing on the floor with a lighter top slab across it.
func _counter(o: Vector2, s: float, x: float, w: float, top_y: float, horizon: float) -> void:
	_rect(o, s, x + 0.02, top_y + 0.05, w - 0.04, horizon - top_y, COUNTER.darkened(0.12), CLEAR, 0.0, 0.0)
	_rect(o, s, x, top_y, w, 0.06, COUNTER, INK, 0.012, 0.01)


## Draws one incident in a 3:2 box of height s at offset o. Returns false for a kind
## with no recipe, which _draw records in painted so a test can pin KINDS to the match.
func _paint(o: Vector2, s: float) -> bool:
	match kind:
		# Low horizon: the beads spread far across the floor, which is the teaching point.
		"mercury_spill":
			_room(o, s, 0.40)
			_counter(o, s, 0.0, 0.52, 0.20, 0.40)
			_rect(o, s, 0.46, 0.60, 0.30, 0.07, SortArt.GLASS, INK, 0.012, 0.01)
			_rect(o, s, 0.84, 0.64, 0.20, 0.07, SortArt.GLASS, INK, 0.012, 0.01)
			draw_circle(_p(o, s, 0.44, 0.635), 0.055 * s, SortArt.MERCURY)
			_poly(o, s, [Vector2(0.78, 0.78), Vector2(0.82, 0.62), Vector2(0.90, 0.76)], SortArt.GLASS, INK, 0.01)
			for bead: Vector3 in [Vector3(0.62, 0.80, 0.055), Vector3(1.06, 0.70, 0.045), Vector3(1.24, 0.86, 0.038), Vector3(1.38, 0.58, 0.030), Vector3(0.30, 0.78, 0.045), Vector3(0.14, 0.56, 0.030), Vector3(0.94, 0.92, 0.028)]:
				draw_circle(_p(o, s, bead.x, bead.y), bead.z * s, SortArt.MERCURY)
			return true
		"chem_spill":
			_room(o, s, 0.72)
			_counter(o, s, 0.0, 1.18, 0.44, 0.72)
			# The bottle lies on its side, so its body is drawn under a rotation.
			draw_set_transform(_p(o, s, 0.36, 0.33), 1.15, Vector2.ONE)
			draw_rect(Rect2(Vector2(-0.11, -0.10) * s, Vector2(0.22, 0.26) * s), SortArt.AMBER)
			draw_rect(Rect2(Vector2(-0.11, -0.10) * s, Vector2(0.22, 0.26) * s), INK, false, 0.012 * s)
			draw_rect(Rect2(Vector2(-0.055, -0.18) * s, Vector2(0.11, 0.08) * s), SortArt.AMBER)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(_p(o, s, 1.06, 0.42), 0.030 * s, SortArt.STEEL_DARK)
			var solvent := Color(SortArt.AMBER.r, SortArt.AMBER.g, SortArt.AMBER.b, 0.62)
			# A lens of solvent on the bench top, a run over the front edge, a floor pool.
			_poly(o, s, [Vector2(0.40, 0.44), Vector2(0.64, 0.38), Vector2(0.94, 0.39), Vector2(1.04, 0.44)], solvent, SortArt.AMBER.darkened(0.2), 0.012)
			_poly(o, s, [Vector2(0.80, 0.50), Vector2(0.88, 0.50), Vector2(0.86, 0.74), Vector2(0.82, 0.74)], solvent)
			_poly(o, s, [Vector2(0.56, 0.86), Vector2(0.80, 0.80), Vector2(1.06, 0.82), Vector2(1.16, 0.90), Vector2(0.94, 0.96), Vector2(0.64, 0.95)], solvent, SortArt.AMBER.darkened(0.2), 0.012)
			_stroke(o, s, [Vector2(0.58, 0.38), Vector2(0.54, 0.31), Vector2(0.59, 0.25), Vector2(0.55, 0.19)], ThemeBuilder.MUTED, 0.012)
			_stroke(o, s, [Vector2(0.76, 0.36), Vector2(0.81, 0.29), Vector2(0.76, 0.23), Vector2(0.81, 0.16)], ThemeBuilder.MUTED, 0.012)
			_stroke(o, s, [Vector2(0.94, 0.38), Vector2(0.90, 0.32), Vector2(0.95, 0.26)], ThemeBuilder.MUTED, 0.012)
			return true
		"water_leak":
			_room(o, s, 0.52)
			_counter(o, s, 0.74, 0.76, 0.22, 0.52)
			_rect(o, s, 0.78, 0.28, 0.70, 0.30, FLOOR.darkened(0.10), CLEAR, 0.0, 0.01)
			# Cabinet door standing open, hinged at the left edge of the carcass.
			_poly(o, s, [Vector2(0.76, 0.28), Vector2(0.76, 0.58), Vector2(0.56, 0.66), Vector2(0.56, 0.36)], COUNTER.lightened(0.10), INK, 0.012)
			_stroke(o, s, [Vector2(1.02, 0.28), Vector2(1.02, 0.44), Vector2(1.20, 0.44), Vector2(1.20, 0.58)], SortArt.STEEL, 0.035)
			draw_circle(_p(o, s, 1.02, 0.44), 0.035 * s, SortArt.STEEL_DARK)
			draw_circle(_p(o, s, 1.03, 0.52), 0.022 * s, WATER)
			draw_circle(_p(o, s, 1.03, 0.61), 0.016 * s, WATER)
			_poly(o, s, [Vector2(0.30, 0.82), Vector2(0.62, 0.72), Vector2(1.06, 0.70), Vector2(1.36, 0.78), Vector2(1.18, 0.93), Vector2(0.54, 0.95)], WATER, WATER.darkened(0.2), 0.012)
			_stroke(o, s, [Vector2(0.62, 0.84), Vector2(0.90, 0.81)], ThemeBuilder.SURFACE, 0.014)
			return true
		# A close-up over the bench: the stick happens while the needle is discarded.
		"needlestick":
			_room(o, s, 0.70)
			_counter(o, s, 0.0, 1.5, 0.70, 1.0)
			_rect(o, s, 0.08, 0.40, 0.30, 0.30, ThemeBuilder.PRIMARY.lerp(ThemeBuilder.SURFACE, 0.72), ThemeBuilder.PRIMARY, 0.014, 0.03)
			_rect(o, s, 0.05, 0.32, 0.36, 0.09, ThemeBuilder.PRIMARY, CLEAR, 0.0, 0.02)
			_rect(o, s, 0.17, 0.345, 0.12, 0.04, ThemeBuilder.SURFACE, CLEAR, 0.0, 0.01)
			var hand: Array[Vector2] = []
			for point: Vector2 in SortArt.GLOVE:
				hand.append(Vector2(0.46 + point.x * 0.86, 0.02 + point.y * 0.86))
			_poly(o, s, hand, SortArt.LATEX, INK, 0.012)
			_rect(o, s, 1.12, 0.14, 0.28, 0.13, ThemeBuilder.SURFACE, INK, 0.012, 0.02)
			_ln(o, s, 1.40, 0.205, 1.46, 0.205, SortArt.STEEL, 0.022)
			_rect(o, s, 1.45, 0.13, 0.04, 0.15, SortArt.STEEL_DARK, CLEAR, 0.0, 0.01)
			_rect(o, s, 1.06, 0.16, 0.07, 0.09, SortArt.STEEL, INK, 0.01)
			_ln(o, s, 1.06, 0.205, 0.92, 0.155, SortArt.STEEL_DARK, 0.018)
			# The bead of blood marks the fingertip the needle went through.
			_poly(o, s, [Vector2(0.90, 0.17), Vector2(0.955, 0.29), Vector2(0.845, 0.29)], SortArt.BLOOD)
			draw_circle(_p(o, s, 0.90, 0.30), 0.055 * s, SortArt.BLOOD)
			return true
		"centrifuge_break":
			_room(o, s, 0.72)
			_counter(o, s, 0.0, 1.5, 0.56, 0.72)
			_rect(o, s, 0.40, 0.28, 0.70, 0.28, ThemeBuilder.SURFACE, INK, 0.014, 0.04)
			# The lid stands open on a hinge at the back-left corner of the body.
			draw_set_transform(_p(o, s, 0.44, 0.30), -0.38, Vector2.ONE)
			draw_rect(Rect2(Vector2(-0.04, -0.07) * s, Vector2(0.58, 0.07) * s), SortArt.STEEL)
			draw_rect(Rect2(Vector2(-0.04, -0.07) * s, Vector2(0.58, 0.07) * s), INK, false, 0.012 * s)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(_p(o, s, 0.44, 0.30), 0.028 * s, SortArt.STEEL_DARK)
			draw_circle(_p(o, s, 0.74, 0.42), 0.14 * s, FLOOR)
			draw_arc(_p(o, s, 0.74, 0.42), 0.14 * s, 0.0, TAU, 48, INK, 0.012 * s)
			for degrees: float in [45.0, 135.0, 225.0, 315.0]:
				var a: float = deg_to_rad(degrees)
				_ln(o, s, 0.74, 0.42, 0.74 + cos(a) * 0.14, 0.42 + sin(a) * 0.14, ThemeBuilder.MUTED, 0.014)
			_rect(o, s, 0.70, 0.32, 0.08, 0.18, SortArt.GLASS, INK, 0.012, 0.02)
			_stroke(o, s, [Vector2(0.70, 0.36), Vector2(0.725, 0.31), Vector2(0.745, 0.37), Vector2(0.78, 0.32)], INK, 0.014)
			_rect(o, s, 0.71, 0.41, 0.06, 0.09, SortArt.BLOOD, CLEAR, 0.0, 0.01)
			draw_circle(_p(o, s, 0.86, 0.38), 0.020 * s, SortArt.BLOOD)
			draw_circle(_p(o, s, 0.62, 0.48), 0.016 * s, SortArt.BLOOD)
			_rect(o, s, 0.94, 0.34, 0.12, 0.06, SortArt.STEEL_DARK, CLEAR, 0.0, 0.01)
			draw_circle(_p(o, s, 0.97, 0.46), 0.022 * s, ThemeBuilder.MUTED)
			draw_circle(_p(o, s, 1.03, 0.46), 0.022 * s, ThemeBuilder.MUTED)
			return true
		"eye_splash":
			_room(o, s, 0.62)
			_counter(o, s, 0.0, 0.50, 0.42, 0.62)
			# The bottle that splashed, still tipped over on the bench.
			draw_set_transform(_p(o, s, 0.22, 0.33), 0.9, Vector2.ONE)
			draw_rect(Rect2(Vector2(-0.07, -0.08) * s, Vector2(0.14, 0.18) * s), SortArt.FORMALIN)
			draw_rect(Rect2(Vector2(-0.07, -0.08) * s, Vector2(0.14, 0.18) * s), INK, false, 0.012 * s)
			draw_rect(Rect2(Vector2(-0.035, -0.13) * s, Vector2(0.07, 0.05) * s), SortArt.STEEL_DARK)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for drop: Vector3 in [Vector3(0.36, 0.26, 0.026), Vector3(0.44, 0.18, 0.022), Vector3(0.52, 0.12, 0.016), Vector3(0.30, 0.33, 0.020)]:
				draw_circle(_p(o, s, drop.x, drop.y), drop.z * s, SortArt.FORMALIN.darkened(0.12))
			# Plumbed eyewash station: pedestal, bowl, twin nozzles running, push paddle.
			_rect(o, s, 0.98, 0.52, 0.07, 0.30, SortArt.STEEL, CLEAR, 0.0, 0.01)
			_rect(o, s, 0.88, 0.80, 0.28, 0.05, SortArt.STEEL_DARK, CLEAR, 0.0, 0.01)
			_poly(o, s, [Vector2(0.78, 0.40), Vector2(1.26, 0.40), Vector2(1.18, 0.54), Vector2(0.86, 0.54)], ThemeBuilder.SURFACE, INK, 0.014)
			_poly(o, s, [Vector2(0.84, 0.48), Vector2(1.20, 0.48), Vector2(1.17, 0.53), Vector2(0.87, 0.53)], WATER)
			_rect(o, s, 0.88, 0.32, 0.08, 0.08, SortArt.STEEL, INK, 0.01)
			_rect(o, s, 1.08, 0.32, 0.08, 0.08, SortArt.STEEL, INK, 0.01)
			# The two jets cross above the bowl, the way a plumbed station runs.
			_stroke(o, s, [Vector2(0.92, 0.30), Vector2(0.97, 0.21), Vector2(1.04, 0.27), Vector2(1.09, 0.44)], WATER, 0.018)
			_stroke(o, s, [Vector2(1.12, 0.30), Vector2(1.07, 0.21), Vector2(1.00, 0.27), Vector2(0.95, 0.44)], WATER, 0.018)
			_rect(o, s, 1.28, 0.44, 0.16, 0.05, ThemeBuilder.SUCCESS, CLEAR, 0.0, 0.01)
			_ln(o, s, 1.20, 0.465, 1.30, 0.465, SortArt.STEEL_DARK, 0.016)
			return true
		"bench_fire":
			_room(o, s, 0.72)
			_counter(o, s, 0.0, 1.12, 0.52, 0.72)
			_poly(o, s, [Vector2(0.34, 0.52), Vector2(0.52, 0.48), Vector2(0.76, 0.49), Vector2(0.88, 0.52)], Color(SortArt.AMBER.r, SortArt.AMBER.g, SortArt.AMBER.b, 0.5))
			_rect(o, s, 0.44, 0.36, 0.18, 0.16, SortArt.GLASS, INK, 0.012, 0.01)
			_poly(o, s, [Vector2(0.53, 0.04), Vector2(0.60, 0.16), Vector2(0.66, 0.12), Vector2(0.63, 0.22), Vector2(0.70, 0.30), Vector2(0.66, 0.40), Vector2(0.53, 0.46), Vector2(0.38, 0.40), Vector2(0.34, 0.28), Vector2(0.43, 0.20), Vector2(0.42, 0.11), Vector2(0.48, 0.17)], FLAME)
			_poly(o, s, [Vector2(0.53, 0.18), Vector2(0.60, 0.29), Vector2(0.55, 0.41), Vector2(0.45, 0.31), Vector2(0.49, 0.24)], FLAME_CORE)
			# Extinguisher standing on the floor clear of the bench.
			_rect(o, s, 1.20, 0.56, 0.18, 0.34, ThemeBuilder.PRIMARY, INK, 0.012, 0.03)
			_rect(o, s, 1.20, 0.68, 0.18, 0.07, ThemeBuilder.SURFACE, CLEAR, 0.0, 0.0)
			_rect(o, s, 1.26, 0.50, 0.06, 0.06, SortArt.STEEL_DARK, CLEAR, 0.0, 0.01)
			_rect(o, s, 1.21, 0.465, 0.16, 0.04, SortArt.STEEL_DARK, CLEAR, 0.0, 0.01)
			_stroke(o, s, [Vector2(1.36, 0.48), Vector2(1.45, 0.58), Vector2(1.44, 0.72), Vector2(1.37, 0.79)], SortArt.STEEL_DARK, 0.016)
			return true
		_:
			return false
