extends GutTest

## A hub tile keeps height equal to width and is tap-guarded like a bench card: a release
## past the drag deadzone is a scroll, not a tap.

const TRAVEL: float = 60.0
const INSIDE_DEADZONE: float = 5.0
const TILE_W: float = 338.0

var _tile: HubTile
var _taps: int = 0


func before_each() -> void:
	_taps = 0
	var row := HBoxContainer.new()
	row.custom_minimum_size.x = TILE_W
	_tile = HubTile.make("Practice", "Any bench, any time", "practice", ThemeBuilder.PRIMARY, func(): _taps += 1)
	row.add_child(_tile)
	add_child_autofree(row)


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


func test_tile_height_follows_width() -> void:
	await wait_process_frames(3)
	assert_true(_tile.size.x >= 300.0, "the tile should fill the row")
	assert_true(absf(_tile.size.y - _tile.size.x) <= 1.0, "a tile should be square")


func test_tile_taps_on_a_release_inside_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_tile, start, start + Vector2(0.0, INSIDE_DEADZONE))
	assert_eq(_taps, 1)


func test_tile_ignores_a_release_past_the_deadzone() -> void:
	var start := Vector2(100.0, 100.0)
	_press_and_release(_tile, start, start + Vector2(0.0, TRAVEL))
	assert_eq(_taps, 0, "travel past the deadzone is a scroll drag")
