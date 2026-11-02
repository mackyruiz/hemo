extends LabStation
## ESR rack (Westergren): run the reference-method demonstration and interpret it.
##
## Phases: SETUP -> TIMER -> READ -> QUESTION. Input outside the live phase is
## ignored and every numeric submission commits exactly once.

const CAPTION := "Reference-method demonstration: EDTA whole blood diluted 4:1 with saline. This is not 9:1 blue-top coagulation preparation. Six seconds represent 60 minutes."
const TILT_TOAST := "A tilted tube speeds sedimentation and falsely raises the ESR. Make it vertical first."
const READ_PROMPT := "Read the ESR at 60 minutes (mm/hr)"
const STEM := "Compared with the displayed approximate age-based upper limit, this ESR is:"
const CHOICES := ["At or below the approximation", "Above the approximation"]
const EXPLANATION := "Miller's rough age estimate: men=age÷2, women=(age+10)÷2 → %.1f mm/hr. This is not a validated reference interval; clinical interpretation uses the lab's method-specific interval. ESR may rise with fibrinogen/globulins (rouleaux), anemia and inflammation; abnormal cell shapes and polycythemia may reduce sedimentation. ESR is nonspecific."

enum Phase { SETUP, TIMER, READ, QUESTION }

var _phase := Phase.SETUP
var _case: Dictionary = {}
var _view: WestergrenView
var _elapsed: Label
var _straighten: Button
var _timer: Button
var _pad: NumPad
var _read_answered := false


func _start() -> void:
	_new_patient()


func _new_patient() -> void:
	_case = EsrLogic.generate(rng)
	_rebuild()


func _rebuild() -> void:
	clear_body()
	_phase = Phase.SETUP
	_read_answered = false
	content.add_child(UI.label("Patient: age %d, sex %s" % [int(_case["age"]), str(_case["sex"])]))
	content.add_child(UI.label(CAPTION, "MutedLabel"))
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = 640.0
	content.add_child(holder)
	_view = WestergrenView.new()
	_view.final_mm = int(_case["final_mm"])
	_view.tilted = bool(_case["tilted"])
	holder.add_child(_view)
	_elapsed = UI.label("Elapsed: 0 min")
	content.add_child(_elapsed)
	_straighten = UI.button("Straighten tube", _straighten_tube, "SecondaryButton")
	_straighten.visible = bool(_case["tilted"])
	content.add_child(_straighten)
	_timer = UI.button("Start 60-minute timer", _start_timer)
	content.add_child(_timer)
	content.add_child(UI.button("New patient", _new_patient, "SecondaryButton"))


func _straighten_tube() -> void:
	if _phase != Phase.SETUP or not bool(_case["tilted"]):
		return
	_case["tilted"] = false
	_view.tilted = false
	_straighten.visible = false


func _start_timer() -> void:
	if _phase != Phase.SETUP:
		return
	if bool(_case["tilted"]):
		# A tilted tube is not vertical: sedimentation is invalid, so refuse.
		UI.toast(self, TILT_TOAST)
		return
	_phase = Phase.TIMER
	_timer.disabled = true
	_straighten.visible = false
	var tween := create_tween()
	track_tween(_view, tween)
	tween.tween_method(_step_timer, 0.0, 60.0, 6.0)
	tween.finished.connect(_timer_finished)


func _step_timer(value: float) -> void:
	if _view == null or not is_instance_valid(_view):
		return
	_view.minutes = value
	_elapsed.text = "Elapsed: %d min" % int(value)


func _timer_finished() -> void:
	if _phase != Phase.TIMER:
		return
	if _view == null or not is_instance_valid(_view) or not content.is_ancestor_of(_view):
		return
	_phase = Phase.READ
	_read_answered = false
	_timer.visible = false
	content.add_child(UI.label(READ_PROMPT))
	_pad = NumPad.new()
	content.add_child(_pad)
	_pad.submitted.connect(_submit_read)


func _submit_read(value: float) -> void:
	if _phase != Phase.READ or _read_answered:
		return
	_read_answered = true
	_pad.visible = false
	var final_mm := int(_case["final_mm"])
	var ok := EsrLogic.read_ok(value, final_mm)
	var status := UI.label("✓ Correct" if ok else "✗ Not quite")
	status.add_theme_color_override("font_color", ThemeBuilder.SUCCESS if ok else ThemeBuilder.ERROR)
	content.add_child(status)
	content.add_child(UI.label("The true 60-minute ESR is %d mm/hr." % final_mm))
	_show_question()


func _show_question() -> void:
	_phase = Phase.QUESTION
	var age := int(_case["age"])
	var sex := str(_case["sex"])
	var limit := EsrLogic.upper_limit(age, sex)
	var above := EsrLogic.is_increased(int(_case["final_mm"]), age, sex)
	content.add_child(UI.label("Approximate age-based upper limit: %.1f mm/hr." % limit))
	content.add_child(UI.label("The sedimentation kinetics shown above are illustrative, not predictive of an individual result.", "MutedLabel"))
	var question := {
		"stem": STEM,
		"choices": CHOICES.duplicate(),
		"answer": 1 if above else 0,
		"image": null,
		"explanation": EXPLANATION % limit,
		"source": "",
	}
	var panel := ask(question)
	panel.next_pressed.connect(_new_patient)
