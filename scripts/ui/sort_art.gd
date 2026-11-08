class_name SortArt
extends Control
## Flat vector graphic for one sortable item or one container target, drawn inside a
## centred square. Item art is material-coloured, never container-tinted: colour must
## not hand over the sort answer.

const ITEM_KINDS := [
	"needle", "lancet", "slide", "broken_tube", "gauze", "glove_soiled",
	"culture_plate", "absorbent_pad", "solvent_bottle", "formalin_jar",
	"wash_bottle", "thermometer", "paper_towel", "cardboard_box",
	"glove_clean", "plastic_wrap",
]
const BIN_KINDS := ["sharps", "biohazard_bag", "chemical_waste", "trash"]

const STEEL := Color("#9AA3AC")
const STEEL_DARK := Color("#6D757E")
const GLASS := Color("#D7E4E9")
const BLOOD := Color("#A3122B")
const AMBER := Color("#C98A1A")
const AGAR := Color("#E8C27A")
const PAPER := Color("#F1EDE7")
const CARD := Color("#C79A6B")
const LATEX := Color("#7FA8D9")
const MERCURY := Color("#8C8F94")
const FORMALIN := Color("#CFE3DF")
const CLEAR := Color(0, 0, 0, 0)
## A mitt with a thumb on the left and four finger humps; shared by both glove kinds.
const GLOVE := [
	Vector2(0.30, 0.92), Vector2(0.26, 0.56), Vector2(0.22, 0.42), Vector2(0.26, 0.34),
	Vector2(0.33, 0.40), Vector2(0.34, 0.22), Vector2(0.41, 0.20), Vector2(0.44, 0.36),
	Vector2(0.50, 0.14), Vector2(0.57, 0.16), Vector2(0.56, 0.38), Vector2(0.63, 0.22),
	Vector2(0.70, 0.26), Vector2(0.66, 0.46), Vector2(0.72, 0.56), Vector2(0.70, 0.92),
]

var kind: String = ""
var tint: Color = ThemeBuilder.PRIMARY   ## container kinds only; ignored by item kinds
var ink: Color = ThemeBuilder.TEXT       ## outline colour, flipped to white while held
var painted: bool = false                ## false after a draw pass with no recipe for kind


static func make(art_kind: String, art_tint: Color) -> SortArt:
	var art := SortArt.new()
	art.kind = art_kind
	art.tint = art_tint
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


static func has_kind(art_kind: String) -> bool:
	return ITEM_KINDS.has(art_kind) or BIN_KINDS.has(art_kind)


## Outlines flip to white when the chip behind them turns dark ink while held.
func set_ink(colour: Color) -> void:
	ink = colour
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	painted = false
	var s: float = minf(size.x, size.y)
	if s < 8.0:
		return
	painted = _paint(Vector2((size.x - s) * 0.5, (size.y - s) * 0.5), s)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


func _rect(o: Vector2, s: float, x: float, y: float, w: float, h: float, fill: Color, border: Color, border_w: float, radius: float = 0.05) -> void:
	ThemeBuilder._box(fill, int(radius * s), border, int(maxf(border_w * s, 1.0)), 0).draw(get_canvas_item(), Rect2(_p(o, s, x, y), Vector2(w * s, h * s)))


func _poly(o: Vector2, s: float, points: Array, fill: Color, outline: Color = CLEAR, outline_w: float = 0.03) -> void:
	var loop := PackedVector2Array()
	for point: Vector2 in points:
		loop.append(o + point * s)
	draw_colored_polygon(loop, fill)
	if outline.a > 0.0:
		loop.append(loop[0])
		draw_polyline(loop, outline, outline_w * s)


func _ln(o: Vector2, s: float, x1: float, y1: float, x2: float, y2: float, colour: Color, w: float) -> void:
	draw_line(_p(o, s, x1, y1), _p(o, s, x2, y2), colour, w * s)


## Biohazard mark: three lobes around a punched-out centre.
func _trefoil(o: Vector2, s: float, cx: float, cy: float, r: float, colour: Color) -> void:
	var center := _p(o, s, cx, cy)
	for degrees: float in [-90.0, 30.0, 150.0]:
		var a: float = deg_to_rad(degrees)
		draw_circle(center + Vector2(cos(a), sin(a)) * (r * 0.52 * s), r * 0.46 * s, colour)
	draw_circle(center, r * 0.30 * s, ThemeBuilder.SURFACE)


## Draws one kind in a square of side s at offset o. Returns false for a kind with no
## recipe, which _draw records in painted so a test can pin KINDS against the match.
func _paint(o: Vector2, s: float) -> bool:
	# Container targets are the only art drawn in a bin tint; item art never reads these.
	var body := tint.lerp(ThemeBuilder.SURFACE, 0.78)
	var edge := tint
	var mark := tint.darkened(0.25)
	match kind:
		"needle":
			_rect(o, s, 0.24, 0.40, 0.42, 0.20, ThemeBuilder.SURFACE, ink, 0.03)
			_rect(o, s, 0.30, 0.42, 0.05, 0.16, STEEL, CLEAR, 0)
			_rect(o, s, 0.66, 0.43, 0.14, 0.14, STEEL, ink, 0.025)
			_ln(o, s, 0.24, 0.50, 0.04, 0.50, STEEL_DARK, 0.055)
			_ln(o, s, 0.80, 0.50, 0.94, 0.50, STEEL, 0.05)
			return true
		"lancet":
			_rect(o, s, 0.28, 0.28, 0.34, 0.44, LATEX, ink, 0.03, 0.08)
			_poly(o, s, [Vector2(0.62, 0.42), Vector2(0.62, 0.58), Vector2(0.90, 0.50)], STEEL_DARK, ink, 0.02)
			_ln(o, s, 0.34, 0.36, 0.56, 0.36, ThemeBuilder.SURFACE, 0.03)
			return true
		"slide":
			_rect(o, s, 0.24, 0.10, 0.46, 0.80, GLASS, ink, 0.03, 0.02)
			_rect(o, s, 0.24, 0.70, 0.46, 0.20, PAPER, ink, 0.03, 0.02)
			_poly(o, s, [Vector2(0.30, 0.26), Vector2(0.64, 0.26), Vector2(0.56, 0.58), Vector2(0.38, 0.58)], BLOOD)
			return true
		"broken_tube":
			_rect(o, s, 0.34, 0.08, 0.32, 0.56, GLASS, ink, 0.03, 0.06)
			draw_polyline(PackedVector2Array([_p(o, s, 0.34, 0.44), _p(o, s, 0.42, 0.54), _p(o, s, 0.50, 0.42), _p(o, s, 0.58, 0.54), _p(o, s, 0.66, 0.44)]), ink, 0.035 * s)
			draw_circle(_p(o, s, 0.50, 0.56), 0.09 * s, BLOOD)
			_poly(o, s, [Vector2(0.12, 0.84), Vector2(0.24, 0.70), Vector2(0.28, 0.86)], GLASS, ink, 0.02)
			_poly(o, s, [Vector2(0.76, 0.80), Vector2(0.88, 0.68), Vector2(0.90, 0.86)], GLASS, ink, 0.02)
			return true
		"gauze":
			_rect(o, s, 0.16, 0.20, 0.68, 0.60, PAPER, ink, 0.03, 0.03)
			_ln(o, s, 0.16, 0.40, 0.84, 0.40, ThemeBuilder.MUTED, 0.02)
			_ln(o, s, 0.16, 0.60, 0.84, 0.60, ThemeBuilder.MUTED, 0.02)
			_ln(o, s, 0.38, 0.20, 0.38, 0.80, ThemeBuilder.MUTED, 0.02)
			_ln(o, s, 0.62, 0.20, 0.62, 0.80, ThemeBuilder.MUTED, 0.02)
			draw_circle(_p(o, s, 0.58, 0.44), 0.16 * s, BLOOD)
			return true
		"glove_soiled":
			_poly(o, s, GLOVE, LATEX, ink, 0.03)
			draw_circle(_p(o, s, 0.52, 0.62), 0.12 * s, BLOOD)
			return true
		# The pair differs only by the blood blot, which is the teaching point.
		"glove_clean":
			_poly(o, s, GLOVE, LATEX, ink, 0.03)
			_ln(o, s, 0.30, 0.84, 0.70, 0.84, ink, 0.025)
			return true
		"culture_plate":
			draw_circle(_p(o, s, 0.50, 0.58), 0.34 * s, AGAR)
			draw_arc(_p(o, s, 0.50, 0.58), 0.34 * s, 0.0, TAU, 48, ink, 0.03 * s)
			draw_arc(_p(o, s, 0.50, 0.46), 0.36 * s, 0.0, TAU, 48, ink, 0.025 * s)
			draw_circle(_p(o, s, 0.40, 0.50), 0.045 * s, ThemeBuilder.MUTED)
			draw_circle(_p(o, s, 0.56, 0.54), 0.035 * s, ThemeBuilder.MUTED)
			draw_circle(_p(o, s, 0.48, 0.68), 0.03 * s, ThemeBuilder.MUTED)
			return true
		"absorbent_pad":
			_rect(o, s, 0.10, 0.30, 0.80, 0.40, PAPER, ink, 0.03, 0.03)
			_ln(o, s, 0.10, 0.38, 0.90, 0.38, ThemeBuilder.MUTED, 0.02)
			draw_circle(_p(o, s, 0.40, 0.50), 0.14 * s, BLOOD)
			draw_circle(_p(o, s, 0.58, 0.54), 0.09 * s, BLOOD)
			return true
		"solvent_bottle":
			_rect(o, s, 0.28, 0.34, 0.44, 0.54, AMBER, ink, 0.03, 0.06)
			_rect(o, s, 0.34, 0.52, 0.32, 0.20, ThemeBuilder.SURFACE, CLEAR, 0, 0.02)
			_rect(o, s, 0.44, 0.18, 0.12, 0.16, AMBER, ink, 0.025, 0.02)
			_rect(o, s, 0.41, 0.08, 0.18, 0.12, STEEL_DARK, CLEAR, 0, 0.02)
			return true
		"formalin_jar":
			_rect(o, s, 0.22, 0.30, 0.56, 0.58, GLASS, ink, 0.03, 0.05)
			_rect(o, s, 0.26, 0.50, 0.48, 0.34, FORMALIN, CLEAR, 0, 0.03)
			_ln(o, s, 0.28, 0.50, 0.72, 0.50, ThemeBuilder.SURFACE, 0.02)
			_rect(o, s, 0.26, 0.16, 0.48, 0.14, STEEL_DARK, CLEAR, 0, 0.03)
			return true
		"wash_bottle":
			_rect(o, s, 0.30, 0.36, 0.40, 0.52, ThemeBuilder.SURFACE, ink, 0.03, 0.08)
			_rect(o, s, 0.34, 0.58, 0.32, 0.26, GLASS, CLEAR, 0, 0.04)
			_rect(o, s, 0.44, 0.22, 0.12, 0.14, STEEL, ink, 0.02, 0.02)
			draw_polyline(PackedVector2Array([_p(o, s, 0.50, 0.22), _p(o, s, 0.50, 0.14), _p(o, s, 0.78, 0.08)]), STEEL_DARK, 0.045 * s)
			return true
		# The gap between the two stems is the break.
		"thermometer":
			_rect(o, s, 0.46, 0.10, 0.10, 0.30, GLASS, ink, 0.025, 0.02)
			_rect(o, s, 0.46, 0.46, 0.10, 0.26, GLASS, ink, 0.025, 0.02)
			_rect(o, s, 0.48, 0.52, 0.06, 0.20, MERCURY, CLEAR, 0, 0.0)
			draw_circle(_p(o, s, 0.51, 0.78), 0.10 * s, MERCURY)
			draw_circle(_p(o, s, 0.26, 0.40), 0.055 * s, MERCURY)
			draw_circle(_p(o, s, 0.74, 0.32), 0.04 * s, MERCURY)
			return true
		"paper_towel":
			_poly(o, s, [Vector2(0.18, 0.74), Vector2(0.14, 0.44), Vector2(0.30, 0.24), Vector2(0.50, 0.34), Vector2(0.68, 0.20), Vector2(0.84, 0.40), Vector2(0.80, 0.76), Vector2(0.50, 0.86)], PAPER, ink, 0.03)
			_ln(o, s, 0.34, 0.36, 0.44, 0.72, ThemeBuilder.MUTED, 0.02)
			_ln(o, s, 0.60, 0.30, 0.66, 0.70, ThemeBuilder.MUTED, 0.02)
			return true
		"cardboard_box":
			_rect(o, s, 0.18, 0.42, 0.64, 0.44, CARD, ink, 0.03, 0.02)
			_poly(o, s, [Vector2(0.18, 0.42), Vector2(0.50, 0.42), Vector2(0.34, 0.24)], CARD.darkened(0.12), ink, 0.02)
			_poly(o, s, [Vector2(0.50, 0.42), Vector2(0.82, 0.42), Vector2(0.66, 0.24)], CARD.darkened(0.20), ink, 0.02)
			_ln(o, s, 0.50, 0.42, 0.50, 0.86, CARD.darkened(0.25), 0.02)
			return true
		"plastic_wrap":
			_poly(o, s, [Vector2(0.14, 0.62), Vector2(0.24, 0.34), Vector2(0.44, 0.44), Vector2(0.58, 0.26), Vector2(0.80, 0.36), Vector2(0.86, 0.66), Vector2(0.60, 0.80), Vector2(0.30, 0.78)], Color(GLASS.r, GLASS.g, GLASS.b, 0.75), ink, 0.025)
			_ln(o, s, 0.34, 0.44, 0.42, 0.72, ThemeBuilder.SURFACE, 0.03)
			_ln(o, s, 0.58, 0.38, 0.68, 0.68, ThemeBuilder.SURFACE, 0.03)
			return true
		"sharps":
			_rect(o, s, 0.20, 0.34, 0.60, 0.54, body, edge, 0.035, 0.05)
			_rect(o, s, 0.16, 0.20, 0.68, 0.16, edge, CLEAR, 0, 0.04)
			_rect(o, s, 0.42, 0.24, 0.16, 0.08, ThemeBuilder.SURFACE, CLEAR, 0, 0.02)
			_trefoil(o, s, 0.50, 0.62, 0.14, mark)
			return true
		"biohazard_bag":
			_poly(o, s, [Vector2(0.26, 0.88), Vector2(0.22, 0.44), Vector2(0.34, 0.28), Vector2(0.66, 0.28), Vector2(0.78, 0.44), Vector2(0.74, 0.88)], body, edge, 0.035)
			_poly(o, s, [Vector2(0.34, 0.28), Vector2(0.42, 0.14), Vector2(0.58, 0.14), Vector2(0.66, 0.28)], edge)
			_trefoil(o, s, 0.50, 0.62, 0.13, mark)
			return true
		"chemical_waste":
			_rect(o, s, 0.24, 0.30, 0.52, 0.58, body, edge, 0.035, 0.06)
			_rect(o, s, 0.42, 0.14, 0.16, 0.16, edge, CLEAR, 0, 0.03)
			_poly(o, s, [Vector2(0.50, 0.44), Vector2(0.66, 0.62), Vector2(0.50, 0.80), Vector2(0.34, 0.62)], ThemeBuilder.SURFACE, mark, 0.03)
			_poly(o, s, [Vector2(0.50, 0.54), Vector2(0.545, 0.63), Vector2(0.455, 0.63)], mark)
			draw_circle(_p(o, s, 0.50, 0.65), 0.05 * s, mark)
			return true
		"trash":
			_poly(o, s, [Vector2(0.28, 0.36), Vector2(0.72, 0.36), Vector2(0.66, 0.88), Vector2(0.34, 0.88)], body, edge, 0.035)
			_rect(o, s, 0.22, 0.24, 0.56, 0.12, edge, CLEAR, 0, 0.03)
			_rect(o, s, 0.44, 0.18, 0.12, 0.06, edge, CLEAR, 0, 0.02)
			_ln(o, s, 0.44, 0.44, 0.42, 0.80, mark, 0.025)
			_ln(o, s, 0.56, 0.44, 0.58, 0.80, mark, 0.025)
			return true
		_:
			return false
