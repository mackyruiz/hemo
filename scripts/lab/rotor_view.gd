class_name RotorView
extends Control
## Rotor head of the microhematocrit centrifuge.
##
## Draws a gray disc with 12 radial slots. Tap a slot to toggle it; the station
## decides how many capillaries may be loaded (max 2, directly opposite). Input
## is off while the rotor spins or the safety lid is closed.

signal slot_tapped(index: int)

const SLOTS := 12
const DISC := Color("#8A8F99")
const DISC_EDGE := Color("#4F535C")
const HUB := Color("#C9CCD3")
const SLOT_EMPTY := Color("#C9CCD3")
const SLOT_LOADED := Color("#B3263E")
const CLAY := Color("#C87F4A")
const LID_TINT := Color(0.10, 0.10, 0.12, 0.42)

var angle: float = 0.0:
	set(value):
		angle = value
		queue_redraw()
var occupied: Array[int] = []:
	set(value):
		occupied = value
		queue_redraw()

## Set false while a phase is busy (spinning, results shown) to ignore taps.
var input_enabled := true
## Drawn as a translucent cover; the station closes it before spinning.
var lid_closed := false:
	set(value):
		lid_closed = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(360, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _slot_radius() -> float:
	return minf(size.x, size.y) / 2.0 - 8.0


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = _slot_radius()
	if radius <= 0.0:
		return
	var r_inner: float = radius * 0.45
	var r_outer: float = radius - 6.0
	draw_circle(center, radius, DISC)
	draw_arc(center, radius, 0.0, TAU, 64, DISC_EDGE, 3.0, true)
	for i in range(SLOTS):
		var a: float = TAU * float(i) / float(SLOTS) + angle
		var dir: Vector2 = Vector2.from_angle(a)
		var loaded: bool = occupied.has(i)
		var color := SLOT_LOADED if loaded else SLOT_EMPTY
		var inner: Vector2 = center + dir * r_inner
		var outer: Vector2 = center + dir * r_outer
		draw_line(inner, outer, color, 16.0, true)
		if loaded:
			# Clay seals sit on the outer end that faces the rotor rim.
			draw_line(center + dir * (r_outer - 14.0), outer, CLAY, 18.0, true)
	draw_circle(center, radius * 0.30, HUB)
	draw_arc(center, radius * 0.30, 0.0, TAU, 48, DISC_EDGE, 2.0, true)
	if lid_closed:
		draw_circle(center, radius, LID_TINT)
		draw_arc(center, radius, 0.0, TAU, 64, ThemeBuilder.ACCENT, 4.0, true)


func _slot_at(point: Vector2) -> int:
	var center: Vector2 = size / 2.0
	var radius: float = _slot_radius()
	if radius <= 0.0:
		return -1
	var offset: Vector2 = point - center
	var dist: float = offset.length()
	if dist < radius * 0.45 - 8.0 or dist > radius - 2.0:
		return -1
	var a: float = atan2(offset.y, offset.x) - angle
	var idx: int = int(round(a / (TAU / float(SLOTS))))
	idx %= SLOTS
	if idx < 0:
		idx += SLOTS
	return idx


func _gui_input(event: InputEvent) -> void:
	if not input_enabled or lid_closed:
		return
	# Touch input also generates an emulated mouse event on mobile. Count once.
	if event is InputEventMouseButton and event.device == -1:
		return
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	accept_event()
	var index: int = _slot_at(point)
	if index < 0:
		return
	slot_tapped.emit(index)
