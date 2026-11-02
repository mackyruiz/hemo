class_name LabJoystick
extends Control
## Local virtual joystick for the Lab Floor.
##
## Deliberately not the engine's `VirtualJoystick`: this widget must not drive
## global `ui_*` actions, and keyboard movement stays a separate input path.
## It captures a single pointer (touch index or real mouse) and reports a
## direction vector of length <= 1.

const BASE_RADIUS := 100.0
const KNOB_RADIUS := 40.0
const KNOB_TRAVEL := 60.0
const DEAD_ZONE := 0.15
## Touch == -1 device mouse events are emulated duplicates; ignore them.
const MOUSE_POINTER := 0

var vector := Vector2.ZERO
var enabled := true

var _pointer := -1


func _ready() -> void:
	custom_minimum_size = Vector2(220, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		reset()


## Clears pointer capture and deflection. Call on release, focus loss, overlay
## opening and tree exit so no stale pointer keeps the player moving.
func reset() -> void:
	_pointer = -1
	vector = Vector2.ZERO
	if is_inside_tree():
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and _pointer == -1 and get_global_rect().has_point(touch.position):
			_pointer = touch.index
			_track(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _pointer:
			_pointer = -1
			vector = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _pointer:
			_track(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index != MOUSE_BUTTON_LEFT or button.device == -1:
			return
		if button.pressed and _pointer == -1 and get_global_rect().has_point(button.position):
			_pointer = MOUSE_POINTER
			_track(button.position)
			accept_event()
		elif not button.pressed and _pointer == MOUSE_POINTER:
			_pointer = -1
			vector = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _pointer == MOUSE_POINTER and motion.device != -1 and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_track(motion.position)
			accept_event()


func _track(global_position: Vector2) -> void:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * global_position
	var offset: Vector2 = local - size * 0.5
	var distance: float = offset.length()
	var magnitude: float = clampf(distance / KNOB_TRAVEL, 0.0, 1.0)
	vector = Vector2.ZERO if distance <= 0.0 else offset / distance * magnitude
	if magnitude < DEAD_ZONE:
		vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, BASE_RADIUS, ThemeBuilder.SURFACE)
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 64, ThemeBuilder.MUTED, 2.0, true)
	var knob_center: Vector2 = center + vector * KNOB_TRAVEL
	var knob_color: Color = ThemeBuilder.PRIMARY if enabled else ThemeBuilder.MUTED
	draw_circle(knob_center, KNOB_RADIUS, knob_color)
