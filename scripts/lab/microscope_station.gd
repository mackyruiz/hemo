extends LabStation
## Microscope station: scan the smear, use oil immersion, focus, and classify
## the cell at the pointer. Sandbox only: never calls Progress or Nav.

const ZONE_NAMES := ["Thick area", "Monolayer", "Feathered edge"]
const PREP_ORDER := ["wright", "retic", "heinz", "kb"]

var logic := ScopeLogic.new()
var _view: ScopeView
var _cells: Array[Dictionary] = []
var _target := ""
var _prep := "wright"
var _phase := "setup"

var _status_label: Label
var _info_label: Label
var _stage_slider: HSlider
var _focus_slider: HSlider
var _oil_button: Button
var _identify_button: Button
var _objective_buttons: Dictionary = {}
var _prep_buttons: Dictionary = {}


func _start() -> void:
	_new_slide()


## Starts one slide. A pending analyzer slide is consumed once; a missing
## pending id clears it and falls back to a practice slide.
func _new_slide(prep: String = "wright") -> void:
	clear_body()
	_phase = "setup"
	var target := ""
	var source_line := ""
	var pending := str(session.get("slide_morph", ""))
	session["slide_morph"] = ""
	if pending != "":
		if Content.morph.has(pending):
			target = pending
			prep = _prep_for(pending)
			source_line = "Patient slide from the analyzer"
		else:
			UI.toast(self, "Requested slide unavailable; showing a practice slide.")
	if target == "":
		target = ScopeLogic.pick_target(Content.morph, rng, prep)
	_target = target
	_prep = prep
	logic.reset(rng, prep)
	_cells = ScopeLogic.layout(CellArt.cell_radius(_target_art(), 1.0), rng)
	_build_ui(source_line)


func _build_ui(source_line: String) -> void:
	var prep_row := HFlowContainer.new()
	# Four long preparation labels do not fit one portrait row; a flow container
	# wraps them instead of clipping the scroll column horizontally.
	prep_row.add_theme_constant_override("h_separation", 8)
	prep_row.add_theme_constant_override("v_separation", 8)
	content.add_child(prep_row)
	var prep_group := ButtonGroup.new()
	for key in PREP_ORDER:
		var button := _toggle(ScopeLogic.PREPARATIONS[key], key == _prep)
		button.button_group = prep_group
		button.pressed.connect(_on_prep_pressed.bind(key))
		prep_row.add_child(button)
		_prep_buttons[key] = button
	if source_line != "":
		content.add_child(UI.label(source_line, "MutedLabel"))
	_status_label = UI.label("")
	content.add_child(_status_label)
	_info_label = UI.label("")
	content.add_child(_info_label)
	_view = ScopeView.new()
	_view.logic = logic
	_view.cells = _cells
	_view.target_art = _target_art()
	content.add_child(_view)
	var stage_row: Array = slider_row("Stage (move slide)", 0.0, 100.0, 1.0)
	_stage_slider = stage_row[1]
	_stage_slider.set_value_no_signal(_stage_to_slider(logic.stage_x))
	_stage_slider.value_changed.connect(_on_stage_changed)
	var objective_row := UI.hbox(8)
	content.add_child(objective_row)
	var objective_group := ButtonGroup.new()
	for o in [10, 40, 100]:
		var button := _toggle(_objective_text(o), o == logic.objective)
		button.button_group = objective_group
		button.pressed.connect(_on_objective_pressed.bind(o))
		objective_row.add_child(button)
		_objective_buttons[o] = button
	_oil_button = UI.button("Add immersion oil", _on_add_oil)
	content.add_child(_oil_button)
	var focus_row: Array = slider_row("Fine focus", 0.0, 100.0, 1.0)
	_focus_slider = focus_row[1]
	_focus_slider.set_value_no_signal(logic.focus)
	_focus_slider.value_changed.connect(_on_focus_changed)
	_identify_button = UI.button("Identify finding", _on_identify)
	content.add_child(_identify_button)
	_refresh()


func _toggle(text: String, on: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(120, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.set_pressed_no_signal(on)
	return button


func _objective_text(o: int) -> String:
	match o:
		10:
			return "10×"
		40:
			return "40×"
		100:
			return "100× oil"
		_:
			return ""


func _prep_for(id: String) -> String:
	match id:
		"retic_nmb":
			return "retic"
		"heinz_body":
			return "heinz"
		"kleihauer_betke":
			return "kb"
		_:
			return "wright"


func _target_art() -> Dictionary:
	var entity: Dictionary = Content.morph.get(_target, {})
	var art: Variant = entity.get("art", {})
	return art if art is Dictionary else {}


func _stage_to_slider(x: float) -> float:
	return (x - ScopeLogic.STAGE_MIN) / (ScopeLogic.STAGE_MAX - ScopeLogic.STAGE_MIN) * 100.0


## Index of the target cell in the identification search circle, or -1.
func _nearest_target_index() -> int:
	if _cells.is_empty():
		return -1
	return ScopeLogic.nearest_target(_cells, Vector2(logic.stage_x, ScopeLogic.VIEW_Y), float(ScopeLogic.VIEW_RADIUS[logic.objective]) * 0.85)


## Recomputes the status/info labels, control states, pointer and view.
func _refresh() -> void:
	var index := _nearest_target_index()
	var reason := logic.blocking_reason(index >= 0)
	_status_label.text = reason if reason != "" else "Ready — identify the cell at the pointer."
	_info_label.text = "%d× · %s%s" % [logic.objective, ZONE_NAMES[logic.zone()], (" · oil" if logic.oil else "")]
	if _phase == "setup":
		_focus_slider.editable = logic.objective != 10
		_oil_button.disabled = logic.oil or _prep == "kb"
		_identify_button.disabled = reason != ""
		_sync_pressed()
		_view.pointer_index = index
	_view.refresh()


## Reverts toggle-button pressed states after a refused change.
func _sync_pressed() -> void:
	for o in _objective_buttons:
		(_objective_buttons[o] as Button).set_pressed_no_signal(o == logic.objective)
	for key in _prep_buttons:
		(_prep_buttons[key] as Button).set_pressed_no_signal(key == _prep)


func _on_prep_pressed(prep: String) -> void:
	if _phase != "setup" or prep == _prep:
		return
	_new_slide(prep)


func _on_objective_pressed(objective: int) -> void:
	if _phase != "setup" or objective == logic.objective:
		return
	var message := logic.select_objective(objective, rng)
	if message != "":
		UI.toast(self, message)
		_sync_pressed()
		return
	_refresh()


func _on_add_oil() -> void:
	if _phase != "setup":
		return
	var message := logic.add_oil()
	if message != "":
		UI.toast(self, message)
		return
	_refresh()


func _on_stage_changed(value: float) -> void:
	if _phase != "setup":
		return
	logic.stage_x = lerpf(ScopeLogic.STAGE_MIN, ScopeLogic.STAGE_MAX, value / 100.0)
	_refresh()


func _on_focus_changed(value: float) -> void:
	if _phase != "setup":
		return
	logic.focus = value
	_refresh()


func _on_identify() -> void:
	if _phase != "setup" or _identify_button.disabled:
		return
	_phase = "answer"
	_stage_slider.editable = false
	_focus_slider.editable = false
	_oil_button.disabled = true
	_identify_button.disabled = true
	for key in _prep_buttons:
		(_prep_buttons[key] as Button).disabled = true
	for o in _objective_buttons:
		(_objective_buttons[o] as Button).disabled = true
	_view.pointer_index = -1
	_view.refresh()
	var entity: Dictionary = Content.morph.get(_target, {})
	var question := {
		"stem": "Identify the cell or finding at the pointer.",
		"choices": ScopeLogic.choices(Content.morph, _target),
		"answer": 0,
		"explanation": str(entity.get("features", "")),
		"image": null,
		"source": str(entity.get("source", "")),
	}
	var panel := ask(question)
	panel.next_pressed.connect(_new_slide)
