extends LabStation
## Specimen receiving: disposition batch plus the CLSI order-of-draw challenge.
##
## Pure sandbox: no Progress/Nav calls, and only the analyzer station writes
## session state. Every submission is guarded so it commits exactly once.

const BATCH_SIZE := 5
const PHASE_ANIMATING := "animating"
const PHASE_SETUP := "setup"
const PHASE_ANSWER := "answer"
const PHASE_FEEDBACK := "feedback"

const ORDER_EXPLANATION := "CLSI order of draw: blood cultures → sodium citrate → serum tubes → heparin → EDTA → glycolytic inhibitor (fluoride). It prevents additive carryover — e.g., EDTA carryover falsely raises potassium and lowers calcium."
const CULTURE_COLOR := Color("#C9A227")
const PLASMA_STRAW := Color("#F2D16B")
const PLASMA_HEMOLYZED := Color("#D9576B")

var _mode := "specimens"
var _phase := PHASE_SETUP
var _batch_index := 0
var _batch_correct := 0
var _current: Dictionary = {}
var _answered := false
var _current_answered := false
var _tally: Label
var _tube: TubeView
var _inspect_button: Button
var _order_button: Button
var _findings: VBoxContainer
var _action_buttons: Array[Button] = []
var _order_step := 0
var _order_busy := false
var _drawn_parts: Array[String] = []
var _drawn_label: Label
var _order_rows: Dictionary = {}
var _order_buttons: Dictionary = {}


func _start() -> void:
	_new_batch()


# --- Specimen mode ---------------------------------------------------------

func _new_batch() -> void:
	_mode = "specimens"
	_batch_index = 0
	_batch_correct = 0
	_current = {}
	_build_specimen(true)


func _build_specimen(regenerate: bool) -> void:
	_mode = "specimens"
	clear_body()
	_action_buttons.clear()
	_answered = false
	_phase = PHASE_ANIMATING
	if regenerate or _current.is_empty():
		_current = SpecimenRules.generate(rng)
		_current_answered = false

	_tally = UI.label("Specimen %d/5 · Correct %d" % [_batch_index + 1, _batch_correct])
	content.add_child(_tally)
	_order_button = UI.button("Order of draw challenge", _start_order)
	_order_button.disabled = true
	content.add_child(_order_button)
	content.add_child(UI.label(SpecimenRules.BATCH_HEADER, "MutedLabel"))

	var requisition: Dictionary = _current["requisition"]
	var req_card: PanelContainer = UI.card()
	req_card.add_child(UI.label("Requisition\nTest: %s\nPatient: %s\nDOB: %s" % [
		String(_current["test"]), String(requisition["name"]), String(requisition["dob"])]))
	content.add_child(req_card)

	var center := CenterContainer.new()
	center.custom_minimum_size.y = 320
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(160, 320)
	center.add_child(holder)
	_tube = TubeView.new()
	_tube.size = Vector2(160, 320)
	holder.add_child(_tube)
	_tube.tube_color = _tube_color(String(_current["tube"]))
	_tube.fill = float(_current["fill"])
	_tube.clotted = String(_current["defect"]) == "clotted"
	_tube.inspected = false
	_tube.position = Vector2(400, 0)

	var label_card: PanelContainer = UI.card()
	label_card.add_child(UI.label("Tube label\n%s\n%s\nDOB %s" % [
		String(_current["label"]["name"]), _tube_additive(String(_current["tube"])), String(_current["label"]["dob"])]))
	content.add_child(label_card)

	_inspect_button = UI.button("Inspect specimen", _inspect)
	_inspect_button.disabled = true
	content.add_child(_inspect_button)

	_findings = UI.vbox(12)
	content.add_child(_findings)

	for i in range(SpecimenRules.ACTIONS.size()):
		var button: Button = UI.button(String(SpecimenRules.ACTION_LABELS[i]), _choose_action.bind(String(SpecimenRules.ACTIONS[i])), "SecondaryButton")
		button.disabled = true
		content.add_child(button)
		_action_buttons.append(button)

	var slide := _tube.create_tween()
	track_tween(_tube, slide)
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_tube, "position:x", 0.0, 0.5)
	slide.finished.connect(_after_slide_in)


func _after_slide_in() -> void:
	if _mode != "specimens" or not is_instance_valid(_tube) or _phase != PHASE_ANIMATING:
		return
	_phase = PHASE_SETUP
	_inspect_button.disabled = false
	if is_instance_valid(_order_button):
		_order_button.disabled = false


func _inspect() -> void:
	if _mode != "specimens" or _phase != PHASE_SETUP or not is_instance_valid(_tube):
		return
	_phase = PHASE_ANIMATING
	_inspect_button.disabled = true
	if is_instance_valid(_order_button):
		_order_button.disabled = true
	var tilt := _tube.create_tween()
	track_tween(_tube, tilt)
	tilt.tween_property(_tube, "tilt_degrees", 35.0, 0.5)
	tilt.tween_property(_tube, "tilt_degrees", 0.0, 0.5)
	tilt.finished.connect(_after_inspection)


func _after_inspection() -> void:
	if _mode != "specimens" or not is_instance_valid(_tube) or _phase != PHASE_ANIMATING:
		return
	_tube.inspected = true
	_phase = PHASE_ANSWER
	if is_instance_valid(_order_button):
		_order_button.disabled = false
	_show_findings()
	for button in _action_buttons:
		button.disabled = false


func _show_findings() -> void:
	if String(_current["defect"]) == "clotted":
		_findings.add_child(UI.label("Visible clot near the bottom of the tube."))
		return
	if String(_current["tube"]) == "light_blue":
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(48, 24)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.color = PLASMA_HEMOLYZED if String(_current["defect"]) == "hemolyzed" else PLASMA_STRAW
		var row: HBoxContainer = UI.hbox(12)
		row.add_child(swatch)
		row.add_child(UI.label("Post-processing plasma inspection"))
		_findings.add_child(row)
	else:
		_findings.add_child(UI.label("No visible clot"))


func _choose_action(action: String) -> void:
	if _mode != "specimens" or _phase != PHASE_ANSWER or _answered:
		return
	_answered = true
	_current_answered = true
	_phase = PHASE_FEEDBACK
	var correct_action := SpecimenRules.correct_action(_current)
	var correct: bool = action == correct_action
	if correct:
		_batch_correct += 1
	if is_instance_valid(_inspect_button):
		_inspect_button.disabled = true
	for i in range(SpecimenRules.ACTIONS.size()):
		var button: Button = _action_buttons[i]
		var value: String = String(SpecimenRules.ACTIONS[i])
		button.disabled = true
		if value == correct_action:
			button.text = "✓ " + String(SpecimenRules.ACTION_LABELS[i])
		elif value == action:
			button.text = "✗ " + String(SpecimenRules.ACTION_LABELS[i])
	var status := UI.label("✓ Correct" if correct else "✗ Incorrect")
	status.add_theme_color_override("font_color", ThemeBuilder.SUCCESS if correct else ThemeBuilder.ERROR)
	content.add_child(status)
	content.add_child(UI.label("Correct action: %s" % String(SpecimenRules.ACTION_LABELS[SpecimenRules.ACTIONS.find(correct_action)])))
	var explanation: PanelContainer = UI.card()
	explanation.add_child(UI.label(SpecimenRules.explanation(_current)))
	content.add_child(explanation)
	content.add_child(UI.button("Next specimen", _next_specimen))
	if is_instance_valid(_tally):
		_tally.text = "Specimen %d/5 · Correct %d" % [_batch_index + 1, _batch_correct]


func _next_specimen() -> void:
	if _mode != "specimens" or _phase != PHASE_FEEDBACK:
		return
	_batch_index += 1
	if _batch_index >= BATCH_SIZE:
		_show_batch_complete()
	else:
		_build_specimen(true)


func _show_batch_complete() -> void:
	_mode = "specimens"
	clear_body()
	_phase = PHASE_FEEDBACK
	content.add_child(UI.label("Batch complete: %d/5 correct" % _batch_correct))
	content.add_child(UI.button("New batch", _new_batch))


# --- Order-of-draw challenge ----------------------------------------------

func _start_order() -> void:
	_mode = "order"
	clear_body()
	_phase = PHASE_SETUP
	_order_step = 0
	_order_busy = false
	_drawn_parts.clear()
	_order_rows.clear()
	_order_buttons.clear()
	content.add_child(UI.label("Order of draw challenge"))
	_drawn_label = UI.label("Drawn:")
	content.add_child(_drawn_label)
	var ids: Array = SpecimenRules.ORDER_OF_DRAW.duplicate()
	_shuffle(ids)
	for raw in ids:
		var id := String(raw)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(0, 72)
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(holder)
		var row: HBoxContainer = UI.hbox(12)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(row)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(24, 24)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.color = CULTURE_COLOR if id == "culture" else Color(String(SpecimenRules.TUBES[id]["color"]))
		row.add_child(swatch)
		var button: Button = UI.button(String(SpecimenRules.ORDER_LABELS[id]), _order_tap.bind(id), "SecondaryButton")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		_order_rows[id] = row
		_order_buttons[id] = button


func _order_tap(id: String) -> void:
	if _mode != "order" or _phase != PHASE_SETUP or _order_busy:
		return
	if _order_step >= SpecimenRules.ORDER_OF_DRAW.size():
		return
	if SpecimenRules.order_step_ok(_order_step, id):
		var button: Button = _order_buttons.get(id, null) as Button
		if button != null:
			button.disabled = true
		_drawn_parts.append(String(SpecimenRules.ORDER_LABELS[id]))
		_order_step += 1
		_drawn_label.text = "Drawn: " + " → ".join(PackedStringArray(_drawn_parts))
		if _order_step >= SpecimenRules.ORDER_OF_DRAW.size():
			_finish_order()
	else:
		_start_shake(_order_rows[id] as Control)
		UI.toast(self, "Next in order: %s" % String(SpecimenRules.ORDER_LABELS[SpecimenRules.ORDER_OF_DRAW[_order_step]]))


func _start_shake(row: Control) -> void:
	if _order_busy:
		return
	_order_busy = true
	var origin_x: float = row.position.x
	var shake := row.create_tween()
	track_tween(row, shake)
	for i in range(4):
		shake.tween_property(row, "position:x", origin_x + 8.0, 0.0375)
		shake.tween_property(row, "position:x", origin_x - 8.0, 0.0375)
	shake.tween_callback(_restore_x.bind(row, origin_x))
	shake.finished.connect(_clear_order_busy)


func _restore_x(row: Control, origin_x: float) -> void:
	if is_instance_valid(row):
		row.position.x = origin_x


func _clear_order_busy() -> void:
	_order_busy = false


func _finish_order() -> void:
	_phase = PHASE_FEEDBACK
	content.add_child(UI.label(ORDER_EXPLANATION, "MutedLabel"))
	content.add_child(UI.button("Back to specimens", _back_to_specimens))


func _back_to_specimens() -> void:
	if _mode != "order":
		return
	if _current_answered:
		_batch_index += 1
		if _batch_index >= BATCH_SIZE:
			_show_batch_complete()
		else:
			_build_specimen(true)
	elif _current.is_empty():
		_new_batch()
	else:
		_build_specimen(false)


# --- Helpers ---------------------------------------------------------------

func _tube_color(id: String) -> Color:
	if id == "culture":
		return CULTURE_COLOR
	return Color(String(SpecimenRules.TUBES[id]["color"]))


func _tube_additive(id: String) -> String:
	if id == "culture":
		return "Blood culture media"
	return String(SpecimenRules.TUBES[id]["additive"])


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
