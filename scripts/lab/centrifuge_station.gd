extends LabStation
## Microhematocrit centrifuge station.
##
## Phases: setup -> animating -> answer -> feedback. Each submission commits
## once (answered guard) and unsafe spins never start an animation.

const PHASE_SETUP := "setup"
const PHASE_ANIMATING := "animating"
const PHASE_ANSWER := "answer"
const PHASE_FEEDBACK := "feedback"

var _phase := PHASE_SETUP
var _sample: Dictionary = {}
var _filled := false
var _sealed := false
var _tubes := 0
var _spin_answered := false
var _numeric_answered := false
var _cap: CapillaryView
var _rotor: RotorView
var _status: Label
var _fill_button: Button
var _seal_button: Button
var _spin_button: Button


func _start() -> void:
	_phase = PHASE_SETUP
	_sample = Microhct.generate(rng)
	_filled = false
	_sealed = false
	_tubes = 0
	_spin_answered = false
	_numeric_answered = false
	_status = UI.label("")
	content.add_child(_status)
	_cap = CapillaryView.new()
	content.add_child(_cap)
	_fill_button = UI.button("Fill capillary (¾ full) from the EDTA tube", _fill)
	content.add_child(_fill_button)
	_seal_button = UI.button("Seal the dry ends with clay", _seal)
	content.add_child(_seal_button)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(360, 360)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(holder)
	_rotor = RotorView.new()
	holder.add_child(_rotor)
	_rotor.position = Vector2.ZERO
	_rotor.size = Vector2(360, 360)
	_rotor.slot_tapped.connect(_on_slot_tapped)
	_spin_button = UI.button("Close lid & spin", _spin)
	content.add_child(_spin_button)
	_update_controls()


func _update_controls() -> void:
	var idle: bool = _phase == PHASE_SETUP
	_fill_button.disabled = not (idle and not _filled)
	_seal_button.disabled = not (idle and _filled and not _sealed)
	_spin_button.disabled = not idle
	_rotor.input_enabled = idle and _filled
	if not _filled:
		_status.text = "Fill a capillary from the EDTA tube."
	elif not _sealed:
		if _tubes == 2:
			_status.text = "Two identical capillaries prepared (sample + duplicate). Seal the dry ends with clay."
		else:
			_status.text = "Seal the dry ends with clay."
	else:
		_status.text = "Load both capillaries 6 slots apart (directly opposite), then close the lid and spin."


func _fill() -> void:
	if _phase != PHASE_SETUP or _filled:
		return
	_phase = PHASE_ANIMATING
	_tubes = 2
	_update_controls()
	var tween := create_tween()
	track_tween(_cap, tween)
	tween.tween_property(_cap, "fill", 0.75, 0.6)
	tween.finished.connect(_after_fill)


func _after_fill() -> void:
	_filled = true
	_phase = PHASE_SETUP
	_update_controls()


func _seal() -> void:
	if _phase != PHASE_SETUP or not _filled or _sealed:
		return
	_sealed = true
	_cap.sealed = true
	_update_controls()


func _on_slot_tapped(index: int) -> void:
	if _phase != PHASE_SETUP or not _filled or _rotor.lid_closed:
		return
	if _rotor.occupied.has(index):
		_rotor.occupied.erase(index)
	elif _rotor.occupied.size() < 2:
		_rotor.occupied.append(index)
	else:
		return
	_rotor.queue_redraw()
	_update_controls()


func _shake_rotor() -> void:
	if _rotor.has_meta("station_tween"):
		var existing: Tween = _rotor.get_meta("station_tween") as Tween
		if existing != null and existing.is_valid():
			existing.kill()
	_rotor.position.x = 0.0
	var step: float = 0.3 / 9.0
	var tween := create_tween()
	track_tween(_rotor, tween)
	for i in range(4):
		tween.tween_property(_rotor, "position:x", 8.0, step)
		tween.tween_property(_rotor, "position:x", -8.0, step)
	tween.tween_property(_rotor, "position:x", 0.0, step)


func _spin() -> void:
	if _phase != PHASE_SETUP or _spin_answered:
		return
	if not _filled:
		UI.toast(self, "Fill a capillary first.")
		return
	if _rotor.occupied.size() != 2 or not Microhct.is_balanced(_rotor.occupied):
		_shake_rotor()
		UI.toast(self, "Rotor unbalanced. Load the duplicate capillary directly opposite (6 slots away).")
		return
	if not _sealed:
		UI.toast(self, "Seal both capillaries before spinning; unsealed tubes can leak. Place sealed ends toward the rotor rim.")
		return
	_spin_answered = true
	_phase = PHASE_ANIMATING
	_rotor.lid_closed = true
	_update_controls()
	_status.visible = false
	content.add_child(UI.label("Spinning… simulated 5 min"))
	content.add_child(UI.label("Time compressed for learning; real speed/time follow the validated instrument procedure.", "MutedLabel"))
	var tween := create_tween()
	track_tween(_rotor, tween)
	tween.tween_property(_rotor, "angle", TAU * 12.0, 3.0)
	tween.finished.connect(_after_spin)


func _after_spin() -> void:
	_phase = PHASE_ANIMATING
	_cap.plasma = String(_sample.get("plasma", "normal"))
	_cap.hct = int(_sample.get("hct", 0))
	var tween := create_tween()
	track_tween(_cap, tween)
	tween.tween_property(_cap, "separation", 1.0, 0.8)
	tween.finished.connect(_show_reading)


func _show_reading() -> void:
	_phase = PHASE_ANSWER
	content.add_child(UI.label("Hct (%) = packed red-cell length ÷ total blood-column length ×100. Exclude buffy coat from the numerator and clay from both lengths."))
	var pad := NumPad.new()
	content.add_child(pad)
	pad.submitted.connect(func(value: float): _on_hct_submit(pad, value))


func _on_hct_submit(pad: NumPad, value: float) -> void:
	if _phase != PHASE_ANSWER or _numeric_answered:
		return
	_numeric_answered = true
	_phase = PHASE_FEEDBACK
	pad.visible = false
	var hct: int = int(_sample.get("hct", 0))
	var ok: bool = Microhct.read_ok(value, hct)
	var text: String = "%s — packed cells %.1f mm ÷ %.0f mm × 100 = %d%%" % [
		"✓ Correct" if ok else "✗ Not quite",
		Microhct.rbc_mm(hct),
		Microhct.COLUMN_MM,
		hct,
	]
	var feedback: Label = UI.label(text)
	feedback.add_theme_color_override("font_color", ThemeBuilder.SUCCESS if ok else ThemeBuilder.ERROR)
	content.add_child(feedback)
	_show_plasma()


func _show_plasma() -> void:
	var correct_key := String(_sample.get("plasma", "normal"))
	if not Microhct.PLASMA_LABELS.has(correct_key):
		correct_key = "normal"
	var choices: Array[String] = [String(Microhct.PLASMA_LABELS[correct_key])]
	for key in ["normal", "icteric", "lipemic", "hemolyzed"]:
		if key != correct_key:
			choices.append(String(Microhct.PLASMA_LABELS[key]))
	var question := {
		"stem": "Plasma appearance?",
		"choices": choices,
		"answer": 0,
		"explanation": String(Microhct.PLASMA_TEXT[correct_key]),
		"image": null,
		"source": ""
	}
	var panel := ask(question)
	panel.next_pressed.connect(func(): call_deferred("_new_sample"))


func _new_sample() -> void:
	clear_body()
	_start()
