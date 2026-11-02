class_name TubeView
extends Control
## Draws one collection tube for the Specimen receiving station.
##
## Pure presentation: the station owns the specimen data and sets `fill`,
## `clotted`, `inspected`, `tube_color` and `tilt_degrees`. Nothing here reads
## autoloads or the shared session.

const GLASS_W := 60.0
const GLASS_H := 260.0
const CAP_W := 70.0
const CAP_H := 36.0
## Nominal intended draw is 80% of the glass body's usable height.
const NOMINAL_FRACTION := 0.8
## The 90%-of-nominal fill mark sits at 72% of the usable height (0.9 * 0.8).
const MIN_LINE_FRACTION := 0.72

const GLASS_BG := Color("#EEF3F7")
const GLASS_RIM := Color("#9AA3AD")
const BLOOD := Color("#7A1424")
const CLOT := Color("#3B0A12")
const LABEL_WHITE := Color("#FFFFFF")
const LABEL_EDGE := Color(0.72, 0.75, 0.78)
const MIN_LINE := Color("#6B6B6B")

## Cap colour supplied by the station (SpecimenRules.TUBES[id].color).
var tube_color := Color("#9B7FD1"):
	set(value):
		tube_color = value
		queue_redraw()
## Fraction of the nominal intended draw volume (1.0 = full nominal draw).
var fill := 1.0:
	set(value):
		fill = value
		queue_redraw()
var clotted := false:
	set(value):
		clotted = value
		queue_redraw()
var inspected := false:
	set(value):
		inspected = value
		queue_redraw()

var tilt_degrees := 0.0:
	set(value):
		tilt_degrees = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(160, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	# Everything is drawn in coordinates centred on the view, then rotated
	# about that centre so the inspection tilt never walks the tube off-frame.
	var pivot: Vector2 = size * 0.5
	draw_set_transform(pivot, deg_to_rad(tilt_degrees), Vector2.ONE)
	var top: float = -(CAP_H + GLASS_H) * 0.5
	var glass := Rect2(-GLASS_W * 0.5, top + CAP_H, GLASS_W, GLASS_H)
	var cap := Rect2(-CAP_W * 0.5, top, CAP_W, CAP_H)

	var body := StyleBoxFlat.new()
	body.bg_color = GLASS_BG
	body.set_corner_radius_all(9)
	draw_style_box(body, glass)

	# Blood rises from the bottom of the glass body; the nominal draw plus the
	# 80% cap still leaves a clear gap below the cap, so it never enters it.
	var level: float = clampf(NOMINAL_FRACTION * GLASS_H * clampf(fill, 0.0, 1.0), 0.0, GLASS_H - 4.0)
	if level > 1.0:
		draw_rect(Rect2(glass.position.x + 2.0, glass.end.y - level, GLASS_W - 4.0, level), BLOOD)
		if inspected and clotted:
			_ellipse(Vector2(0.0, glass.end.y - 20.0), 16.0, 7.0, CLOT)
			_ellipse(Vector2(-9.0, glass.end.y - 30.0), 10.0, 5.0, CLOT)
			_ellipse(Vector2(8.0, glass.end.y - 34.0), 9.0, 4.5, CLOT)

	# 90% minimum-fill mark.
	var min_y: float = glass.end.y - MIN_LINE_FRACTION * GLASS_H
	draw_line(Vector2(glass.position.x + 2.0, min_y), Vector2(glass.end.x - 2.0, min_y), MIN_LINE, 1.5)

	# Narrow white label rectangle; purely illustrative, the station shows the
	# full identifiers in its "Tube label" card.
	var sticker := Rect2(-20.0, glass.position.y + 6.0, 40.0, 40.0)
	draw_rect(sticker, LABEL_WHITE)
	draw_rect(sticker, LABEL_EDGE, false, 1.0)

	var rim := StyleBoxFlat.new()
	rim.bg_color = Color(0, 0, 0, 0)
	rim.border_color = GLASS_RIM
	rim.set_border_width_all(2)
	rim.set_corner_radius_all(9)
	draw_style_box(rim, glass)

	var cap_box := StyleBoxFlat.new()
	cap_box.bg_color = tube_color
	cap_box.set_corner_radius_all(6)
	draw_style_box(cap_box, cap)


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, color)
