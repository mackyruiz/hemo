class_name CapillaryView
extends Control
## The microhematocrit capillary tube.
##
## Before spinning it shows the blood column filling the tube; after spinning
## `separation` blends into packed cells / buffy coat / plasma. The ruler maps
## the 50 mm blood column: 0 at the clay top, 50 at the plasma top, 10 px/mm.

const PX_PER_MM := 10.0
const TUBE_WIDTH := 56.0
const CLAY_HEIGHT := 26.0
const BOTTOM_MARGIN := 8.0
const BLOOD_COLOR := Color("#7A1424")
const PACKED_COLOR := Color("#B3263E")
const BUFFY_COLOR := Color("#F0EAD6")
const CLAY := Color("#C87F4A")
const GLASS := Color("#EEF3F7")
const RIM := Color("#9AA3AD")

## Fraction of the tube filled (0..0.75); 0.75 is "three-quarters full".
var fill: float = 0.0:
	set(value):
		fill = value
		queue_redraw()
## 0 = uniform whole blood, 1 = fully separated layers.
var separation: float = 0.0:
	set(value):
		separation = value
		queue_redraw()
var hct: int = 0:
	set(value):
		hct = value
		queue_redraw()
var plasma: String = "normal":
	set(value):
		plasma = value
		queue_redraw()
var sealed: bool = false:
	set(value):
		sealed = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(200, 560)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _blood_mm() -> float:
	# Filling the tube to three-quarters reaches the full blood column.
	return clampf(fill / 0.75, 0.0, 1.0) * Microhct.COLUMN_MM


func _draw() -> void:
	var col_h: float = Microhct.COLUMN_MM * PX_PER_MM
	var tube_x: float = (size.x - TUBE_WIDTH) / 2.0
	var clay_bottom: float = size.y - BOTTOM_MARGIN
	var y_zero: float = clay_bottom - CLAY_HEIGHT
	var y_top: float = y_zero - col_h
	# Glass tube body.
	draw_rect(Rect2(tube_x, y_top - 12.0, TUBE_WIDTH, clay_bottom - (y_top - 12.0)), GLASS, true)
	draw_rect(Rect2(tube_x, y_top - 12.0, TUBE_WIDTH, clay_bottom - (y_top - 12.0)), RIM, false, 2.0)
	var x0: float = tube_x + 6.0
	var inner_w: float = TUBE_WIDTH - 12.0
	var full_mm: float = _blood_mm()
	if full_mm > 0.0:
		var rbc_mm: float = Microhct.rbc_mm(hct)
		var packed_top: float = lerpf(full_mm, rbc_mm, separation)
		var buffy_top: float = lerpf(full_mm, minf(rbc_mm + 0.8, Microhct.COLUMN_MM), separation)
		# Packed red cells sit on the clay; clay is not part of the length.
		draw_rect(Rect2(x0, y_zero - packed_top * PX_PER_MM, inner_w, packed_top * PX_PER_MM), PACKED_COLOR, true)
		var buffy_mm: float = maxf(buffy_top - packed_top, 0.0)
		draw_rect(Rect2(x0, y_zero - buffy_top * PX_PER_MM, inner_w, buffy_mm * PX_PER_MM), BUFFY_COLOR, true)
		var plasma_mm: float = maxf(full_mm - buffy_top, 0.0)
		var plasma_color: Color = Microhct.PLASMA.get(plasma, Microhct.PLASMA["normal"])
		draw_rect(Rect2(x0, y_zero - full_mm * PX_PER_MM, inner_w, plasma_mm * PX_PER_MM), plasma_color, true)
	if sealed:
		draw_rect(Rect2(x0, y_zero, inner_w, CLAY_HEIGHT), CLAY, true)
	_draw_ruler(tube_x - 8.0, y_zero)


func _draw_ruler(tick_x: float, y_zero: float) -> void:
	var font: Font = get_theme_default_font()
	for m in range(int(Microhct.COLUMN_MM) + 1):
		var y: float = y_zero - float(m) * PX_PER_MM
		var is_label: bool = m % 5 == 0
		var length: float = 11.0 if is_label else 6.0
		draw_line(Vector2(tick_x - length, y), Vector2(tick_x, y), ThemeBuilder.MUTED, 1.0, true)
		if is_label:
			draw_string(font, Vector2(tick_x - 54.0, y + 4.0), str(m), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ThemeBuilder.MUTED)
