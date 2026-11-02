extends GutTest

## A press that travels past the deadzone is a scroll drag, not a tap: UI.button and
## UI.tappable must ignore such a release so a drag that starts on a control still scrolls
## the panel, which is the only way to move a ScrollContainer on a phone.
##
## These tests drive the guards directly by emitting the events the guard listens to; GUI
## picking itself is engine behaviour and is verified in the web build.

const TRAVEL: float = 60.0
const INSIDE_DEADZONE: float = 5.0

var _button: Button
var _card: PanelContainer
var _button_clicks: int = 0
var _card_taps: int = 0


func before_each() -> void:
	_button_clicks = 0
	_card_taps = 0
	_button = UI.button("Choice", func(): _button_clicks += 1)
	add_child_autofree(_button)
	_card = UI.card()
	UI.tappable(_card, func(): _card_taps += 1)
	add_child_autofree(_card)


func _press_and_release(control: Control, from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.global_position = from
	control.emit_signal("gui_input", down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.global_position = to
	control.emit_signal("gui_input", up)


func test_button_clicks_on_a_release_inside_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_button, start, start + Vector2(0.0, INSIDE_DEADZONE))
	_button.pressed.emit()
	assert_eq(_button_clicks, 1, "a tap should still click the button")


func test_button_ignores_a_release_past_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_button, start, start + Vector2(0.0, TRAVEL))
	_button.pressed.emit()
	assert_eq(_button_clicks, 0, "a scroll drag should not click the button")


func test_card_taps_on_a_release_inside_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_card, start, start + Vector2(0.0, INSIDE_DEADZONE))
	assert_eq(_card_taps, 1)


func test_card_ignores_a_release_past_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_card, start, start + Vector2(0.0, TRAVEL))
	assert_eq(_card_taps, 0)


func test_card_ignores_a_release_just_past_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_card, start, start + Vector2(0.0, UI.DRAG_DEADZONE + 1.0))
	assert_eq(_card_taps, 0, "travel just past the deadzone is a drag, not a tap")


func test_controls_inside_scroll_content_pass_events_to_the_container() -> void:
	# Stop filtering eats the press, so a drag starting on a control never reaches the
	# ScrollContainer and the panel cannot be dragged at all on a phone.
	assert_eq(_button.mouse_filter, Control.MOUSE_FILTER_PASS)
	assert_eq(_card.mouse_filter, Control.MOUSE_FILTER_PASS)


## The phone path: screen-touch events arrive with no global position, and the control moves
## with the content while the finger is held down, so the guard has to measure pointer travel
## in absolute coordinates, not travel relative to the control.
func _screen_press_and_release(control: Control, at: Vector2, drag: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.pressed = true
	down.position = at
	assert_null(down.get("global_position"), "screen touches carry no global position in the web build")
	control.emit_signal("gui_input", down)
	control.global_position = control.global_position + drag
	var up := InputEventScreenTouch.new()
	up.pressed = false
	up.position = at
	control.emit_signal("gui_input", up)


func test_card_taps_on_a_screen_touch_inside_the_deadzone() -> void:
	_screen_press_and_release(_card, Vector2(30.0, 30.0), Vector2(0.0, INSIDE_DEADZONE))
	assert_eq(_card_taps, 1, "a finger that stays inside the card is a tap")


func test_card_ignores_a_screen_touch_drag_that_scrolls_the_card() -> void:
	_screen_press_and_release(_card, Vector2(30.0, 30.0), Vector2(0.0, TRAVEL))
	assert_eq(_card_taps, 0, "the card moved with the content, so this was a scroll drag")


func test_button_ignores_a_screen_touch_drag_that_scrolls_the_button() -> void:
	_screen_press_and_release(_button, Vector2(30.0, 30.0), Vector2(0.0, TRAVEL))
	_button.pressed.emit()
	assert_eq(_button_clicks, 0, "a scroll drag should not click the button")
