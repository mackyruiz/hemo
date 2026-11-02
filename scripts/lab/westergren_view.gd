class_name WestergrenView
extends Control
## Westergren ESR tube: a 200 mm column at 2.6 px/mm with 0 mm at the top.
##
## Plasma is drawn from the zero mark down to the current sedimentation front
## (`EsrLogic.front_mm`); packed red cells fill the column below the front. The
## whole tube is rotated about its centre while the rack is still tilted.

const MM_SPAN := 200.0
const PX_PER_MM := 2.6
const TUBE_WIDTH := 26.0
const TILT_DEGREES := 10.0
const MARKS_EVERY_MM := 10

const PLASMA_COLOR := Color("#F2D16B")
const CELL_COLOR := Color("#B3263E")
const GLASS_COLOR := Color("#EEF3F7")
const RIM_COLOR := Color("#9AA3AD")
const MARK_COLOR := Color("#6B6B6B")

## Minutes of settling shown so far.
var minutes: float = 0.0:
	set(value):
		minutes = value
		queue_redraw()
## Final 60-minute reading for this patient.
var final_mm: int = 0:
	set(value):
		final_mm = value
		queue_redraw()
## True while the tube is not vertical; sedimentation is then not valid.
var tilted: bool = false:
	set(value):
		tilted = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(200, 620)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Height of the plasma column in millimetres at the current elapsed time.
func front_mm() -> float:
	return EsrLogic.front_mm(minutes, final_mm)


func _draw() -> void:
	var column_height := MM_SPAN * PX_PER_MM
	var center := size * 0.5
	draw_set_transform(center, deg_to_rad(TILT_DEGREES) if tilted else 0.0, Vector2.ONE)
	var half := TUBE_WIDTH * 0.5
	var top := -column_height * 0.5
	var front := clampf(front_mm(), 0.0, MM_SPAN) * PX_PER_MM
	# Glass, then packed red cells below the front and plasma above it.
	draw_rect(Rect2(-half, top, TUBE_WIDTH, column_height), GLASS_COLOR, true)
	draw_rect(Rect2(-half, top + front, TUBE_WIDTH, column_height - front), CELL_COLOR, true)
	draw_rect(Rect2(-half, top, TUBE_WIDTH, front), PLASMA_COLOR, true)
	draw_rect(Rect2(-half, top, TUBE_WIDTH, column_height), RIM_COLOR, false, 2.0)
	# Millimetre scale, 0 at the top and 200 at the bottom.
	var label_font := get_theme_default_font()
	for mm in range(0, int(MM_SPAN) + MARKS_EVERY_MM, MARKS_EVERY_MM):
		var y := top + float(mm) * PX_PER_MM
		draw_line(Vector2(half, y), Vector2(half + 6.0, y), MARK_COLOR, 1.0)
		draw_string(label_font, Vector2(half + 10.0, y + 6.0), str(mm), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MARK_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
