extends Control
## Lab Floor: walkable top-down lab sandbox with hands-on instrument stations.
##
## Nothing on this screen writes progress. The only graded path is the LIS
## terminal, which asks for confirmation and then leaves for existing Practice.

const SPEED := 3.5
const FRAME_TIME := 0.12
## Stations that need loaded learning content (morphology / CBC cases).
const LEARNING_STATIONS := ["microscope", "receiving", "centrifuge", "analyzer", "esr"]
const CONTENT_MESSAGE := "Lab learning content is unavailable. Return to the hub and check content loading."

var _pos := LabMap.SPAWN
var _facing := LabSprites.DIR_UP
var _anim_t := 0.0
var _walk_i := 0
var _walking := false
var _keys_armed := true
var _focused := true
var _station: LabStation = null
var _dialog: ConfirmationDialog = null
var _session := {"qc_done": false, "slide_morph": ""}

var _view: LabView
var _joystick: LabJoystick
var _prompt: Label
var _use: Button
var _hud: Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	outer.add_child(_build_top())
	_view = LabView.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(_view)
	_hud = _build_hud()
	outer.add_child(_hud)
	_refresh_view(true)


func _build_top() -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.add_theme_constant_override("margin_bottom", 0)
	var column := UI.vbox(4)
	margin.add_child(column)

	var row := UI.hbox(12)
	var hub := UI.button("‹ Hub", func(): Nav.back(), "SecondaryButton")
	hub.custom_minimum_size.x = 120
	hub.focus_mode = Control.FOCUS_NONE
	row.add_child(hub)
	var title := UI.label("Lab Floor", "TitleLabel")
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	column.add_child(row)

	column.add_child(UI.label("Sandbox — practice freely, no XP", "MutedLabel"))
	if not _content_available():
		column.add_child(UI.label(CONTENT_MESSAGE))
	return margin


func _build_hud() -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "bottom", "top"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	var row := UI.hbox(12)
	margin.add_child(row)

	_joystick = LabJoystick.new()
	row.add_child(_joystick)

	var column := UI.vbox(8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(column)

	_prompt = UI.label("Walk to a station, then press Use.")
	column.add_child(_prompt)

	_use = UI.button("Use", _interact)
	_use.custom_minimum_size.y = 96
	_use.focus_mode = Control.FOCUS_NONE
	_use.disabled = true
	column.add_child(_use)

	column.add_child(UI.label("WASD / arrows to move · E to use", "MutedLabel"))
	return margin


func _content_available() -> bool:
	return Content.load_errors.is_empty() and not Content.morph.is_empty() and not Content.cbc_cases.is_empty()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_focused = false
		_keys_armed = false
		if _joystick != null:
			_joystick.reset()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_focused = true
		_keys_armed = false
		if _joystick != null:
			_joystick.reset()


func _process(delta: float) -> void:
	if _station != null or _dialog != null:
		return
	if not _focused:
		return
	var keyboard := _keyboard_vector()
	var motion: Vector2 = keyboard if keyboard != Vector2.ZERO else _joystick.vector
	if motion.length() > 1.0:
		motion = motion.normalized()
	var moved: Vector2 = LabMap.move(_pos, motion * SPEED * delta)
	var did_move: bool = not moved.is_equal_approx(_pos)
	_pos = moved
	_anim_t += delta if did_move else 0.0
	_walk_i = int(_anim_t / FRAME_TIME) % 2
	_walking = did_move
	if did_move:
		_orient(motion)
	_refresh_view(did_move or _walking or _station_nearby())
	if _view.highlight != "":
		_view.pulse = fmod(_view.pulse + delta, TAU)


func _keyboard_vector() -> Vector2:
	if get_viewport().gui_get_focus_owner() != null:
		return Vector2.ZERO
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	if not _keys_armed:
		# Any key still held at overlay/dialog close must be released first so
		# the player never resumes walking from a stale press.
		if v != Vector2.ZERO:
			return Vector2.ZERO
		_keys_armed = true
	return v


func _orient(motion: Vector2) -> void:
	if absf(motion.x) >= absf(motion.y):
		_facing = LabSprites.DIR_RIGHT if motion.x > 0.0 else LabSprites.DIR_LEFT
	else:
		_facing = LabSprites.DIR_DOWN if motion.y > 0.0 else LabSprites.DIR_UP


func _station_nearby() -> bool:
	return LabMap.nearest_station(_pos) != ""


func _refresh_view(redraw: bool) -> void:
	_view.player_pos = _pos
	_view.facing = _facing
	_view.walk_row = LabSprites.WALK_ROWS[_facing] if _walking and _walk_i == 0 else 0
	var near: String = LabMap.nearest_station(_pos)
	_view.highlight = near
	if near == "":
		_prompt.text = "Walk to a station, then press Use."
		_use.disabled = true
	else:
		_prompt.text = "Near %s — press Use." % str(LabMap.STATION_NAMES.get(near, near))
		_use.disabled = false
	if redraw:
		_view.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	if key.physical_keycode != KEY_E:
		return
	if _station != null or _dialog != null:
		return
	get_viewport().set_input_as_handled()
	_interact()


func _interact() -> void:
	var id: String = LabMap.nearest_station(_pos)
	if id == "":
		return
	match id:
		"lis":
			_confirm_leave()
		"exit":
			Nav.back()
		_:
			_open_station(id)


func _confirm_leave() -> void:
	if _dialog != null:
		return
	_joystick.reset()
	var dialog: ConfirmationDialog = UI.confirm_dialog(
		"Leave sandbox for Practice?",
		"Practice saves XP/mastery. Lab Floor activities do not.",
		"Open Practice",
		"Stay in lab"
	)
	dialog.focus_mode = Control.FOCUS_NONE
	_dialog = dialog
	add_child(dialog)
	dialog.confirmed.connect(func():
		_drop_dialog()
		Nav.go("practice")
	)
	dialog.canceled.connect(_drop_dialog)
	dialog.close_requested.connect(_drop_dialog)
	UI.popup_confirm(dialog)


func _drop_dialog() -> void:
	if _dialog == null:
		return
	var dialog: ConfirmationDialog = _dialog
	_dialog = null
	remove_child(dialog)
	dialog.queue_free()
	_keys_armed = false
	_joystick.reset()


func _open_station(id: String) -> void:
	if _station != null:
		return
	if LEARNING_STATIONS.has(id) and not _content_available():
		UI.toast(self, CONTENT_MESSAGE)
		return
	_joystick.reset()
	_joystick.enabled = false
	_hud.visible = false
	var script: GDScript = load("res://scripts/lab/%s_station.gd" % id) as GDScript
	var station: LabStation = script.new() as LabStation
	station.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(station)
	station.set_anchors_preset(Control.PRESET_FULL_RECT)
	_station = station
	station.closed.connect(_close_station)
	station.open(_session, str(LabMap.STATION_NAMES.get(id, id)))


func _close_station() -> void:
	if _station == null:
		return
	var station: LabStation = _station
	_station = null
	remove_child(station)
	station.queue_free()
	_hud.visible = true
	_joystick.enabled = true
	_joystick.reset()
	_keys_armed = false
	_refresh_view(true)


## Nav.back() contract: close the overlay first, then leave on the next request.
func can_leave() -> bool:
	if _station != null:
		_close_station()
		return false
	return true
