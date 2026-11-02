extends LabStation
## Hematology analyzer: daily QC gate, then a patient CBC run and review decision.
##
## Phases: QC -> PATIENT_IDLE -> ANIMATING -> REPORT. `session["qc_done"]` is
## only set by a correct QC accept, so patient loading cannot be bypassed.

const QC_WARN := "1-2s warning alone is not rejection under this exercise's multirule policy; review the control history."
const QC_REJECT := "1-3s violation: stop reporting, investigate and resolve the cause, then rerun QC."
const QC_PASS := "Controls meet the acceptance limits for this exercise's multirule policy."
const QC_RESOLVED := "Simulated issue resolved: the cause of the violation was investigated and corrected. A confirmation QC run has been generated — review it, then accept or reject."
const SMEAR_AUTHORED := "Manual smear review requested for this training case."
const SMEAR_SYNTHETIC := "No smear-review request; identity, specimen integrity, QC and verification checks passed in this scenario."
const STEM := "What is the next action under the displayed training order?"
const CHOICES := [
	"Release under the verified lab policy",
	"Hold and review the requested peripheral smear",
	"Hold: investigate suspected interference before reporting",
]
const EXPLAIN_RELEASE := "Scenario verification checks passed and no review is requested. Normal reference flags alone never authorize release in a real lab."
const EXPLAIN_SMEAR := "This case explicitly requests smear review. Complete it before release. An out-of-range result alone is not a universal smear criterion."
const EXPLAIN_INVESTIGATE := "The vignette or flag suggests interference. Hold affected results, investigate and follow the lab procedure before reporting. "
const ACTION_INDEX := {"release": 0, "smear": 1, "investigate": 2}
const SYNTHETIC_VIGNETTE := "Routine pre-operative CBC."
const TUBE_START_X := 216.0
const TUBE_END_X := 132.0

enum Phase { QC, PATIENT_IDLE, ANIMATING, REPORT }

var _phase := Phase.QC
var _case: Dictionary = {}
var _qc: Dictionary = {}
var _qc_settled := false
var _qc_status: Label
var _qc_message: Label
var _qc_troubleshoot: Button
var _history_box: VBoxContainer
var _report_answered := false
var _slide_placed := false
var _slide_button: Button


func _start() -> void:
	clear_body()
	_build_art()
	if bool(session.get("qc_done", false)):
		_build_patient_idle()
	else:
		_build_qc_intro()


func _build_qc_intro() -> void:
	_phase = Phase.QC
	content.add_child(UI.label("Daily quality control has not been accepted for this shift."))
	content.add_child(UI.button("Run daily QC", _run_qc))


func _run_qc() -> void:
	if _phase != Phase.QC:
		return
	clear_body()
	_build_art()
	_qc = QcGenerator.generate(_pick_qc_scenario(), rng)
	_build_qc_body("")


# ---------------------------------------------------------------- header art

## Adds the analyzer sprite and returns the fixed-size holder it lives in.
func _build_art() -> Control:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(192, 192)
	center.add_child(holder)
	var art := TextureRect.new()
	art.texture = LabSprites.device_texture("analyzer")
	art.custom_minimum_size = Vector2(192, 192)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(art)
	return holder


# ------------------------------------------------------------------ QC gate

func _pick_qc_scenario() -> String:
	return ["none", "1_2s", "1_3s"][rng.randi_range(0, 2)]


func _qc_rules() -> Array:
	var level1: Array[float] = []
	var level2: Array[float] = []
	level1.assign(_qc["levels"][0]["z"])
	level2.assign(_qc["levels"][1]["z"])
	return Westgard.evaluate(level1, level2)


func _build_qc_body(note: String) -> void:
	_phase = Phase.QC
	_qc_settled = false
	content.add_child(UI.label("Daily quality control — run both control levels before reporting patient results."))
	if not note.is_empty():
		content.add_child(UI.label(note))
	_add_qc_table()
	_add_qc_history()
	_qc_status = UI.label("")
	content.add_child(_qc_status)
	_qc_message = UI.label("")
	content.add_child(_qc_message)
	content.add_child(UI.button("Accept QC — run patients", func(): _qc_decision(true)))
	content.add_child(UI.button("Reject QC — troubleshoot", func(): _qc_decision(false), "SecondaryButton"))
	_qc_troubleshoot = UI.button("Troubleshoot and rerun QC", _qc_troubleshoot_pressed, "SecondaryButton")
	_qc_troubleshoot.visible = Westgard.is_reject(_qc_rules())
	content.add_child(_qc_troubleshoot)


func _add_qc_table() -> void:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for heading in ["Level", "Analyte/unit", "Last result", "Mean±SD", "Last z-score"]:
		grid.add_child(_cell(heading, true))
	for level in _qc["levels"]:
		var values: Array = level["values"]
		var points: Array = level["z"]
		grid.add_child(_cell(str(level["name"])))
		grid.add_child(_cell("%s (%s)" % [str(_qc["analyte"]), str(_qc["unit"])]))
		grid.add_child(_cell(str(values[-1])))
		grid.add_child(_cell("%.2f ± %.2f" % [float(level["mean"]), float(level["sd"])]))
		grid.add_child(_cell("%.2f" % float(points[-1])))
	content.add_child(grid)
	content.add_child(UI.label("These are control target values from the instrument's QC program, not patient reference intervals.", "MutedLabel"))


func _add_qc_history() -> void:
	content.add_child(UI.button("Control history (SD from target)", _toggle_history, "SecondaryButton"))
	_history_box = UI.vbox(4)
	_history_box.visible = false
	content.add_child(_history_box)
	for level in _qc["levels"]:
		var points: Array = level["z"]
		var text := ""
		for i in range(points.size()):
			if i > 0:
				text += ", "
			text += "%.2f" % float(points[i])
		_history_box.add_child(UI.label("%s: %s" % [str(level["name"]), text], "MutedLabel"))


func _toggle_history() -> void:
	if _history_box == null or not is_instance_valid(_history_box):
		return
	_history_box.visible = not _history_box.visible


func _qc_decision(accept: bool) -> void:
	if _phase != Phase.QC or _qc_settled:
		return
	var rules := _qc_rules()
	var rejecting: bool = Westgard.is_reject(rules)
	var correct: bool = accept != rejecting
	_qc_status.text = "✓ Correct" if correct else "✗ Incorrect"
	_qc_status.add_theme_color_override("font_color", ThemeBuilder.SUCCESS if correct else ThemeBuilder.ERROR)
	if rejecting:
		_qc_message.text = QC_REJECT
	else:
		_qc_message.text = QC_WARN if rules.has("1_2s") else QC_PASS
	_qc_troubleshoot.visible = rejecting
	if accept and correct:
		# Only a correct accept unlocks patient testing.
		session["qc_done"] = true
		_qc_settled = true
		content.add_child(UI.button("Load next sample", _load_next_sample))


func _qc_troubleshoot_pressed() -> void:
	if _phase != Phase.QC or _qc_settled:
		return
	clear_body()
	_build_art()
	_qc = QcGenerator.generate("none", rng)
	_build_qc_body(QC_RESOLVED)


func _build_patient_idle() -> void:
	_phase = Phase.PATIENT_IDLE
	content.add_child(UI.label("Daily QC accepted. Load a patient sample to run."))
	content.add_child(UI.button("Load next sample", _load_next_sample))


# -------------------------------------------------------------- patient run

func _pick_case() -> Dictionary:
	if rng.randf() < 0.3 or Content.cbc_cases.is_empty():
		var sex := "M" if rng.randi_range(0, 1) == 0 else "F"
		return {
			"age": rng.randi_range(20, 80),
			"sex": sex,
			"cbc": AnalyzerLogic.normal_cbc(sex, rng),
			"spurious": false,
			"smear": [],
			"vignette": SYNTHETIC_VIGNETTE,
		}
	var picked: Dictionary = Content.cbc_cases[rng.randi_range(0, Content.cbc_cases.size() - 1)]
	# Authored cases are read-only shared content.
	return picked.duplicate(true)


func _load_next_sample() -> void:
	if _phase == Phase.ANIMATING or not bool(session.get("qc_done", false)):
		return
	_case = _pick_case()
	if _case.is_empty():
		return
	_report_answered = false
	_slide_placed = false
	_slide_button = null
	_phase = Phase.ANIMATING
	clear_body()
	var holder := _build_art()
	var tube := _build_tube(holder)
	var tween := create_tween()
	track_tween(tube, tween)
	tween.tween_property(tube, "position:x", TUBE_END_X, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_show_analyzing)


## Builds the lavender-top sample tube inside `parent` and returns it.
func _build_tube(parent: Control) -> ColorRect:
	var tube := ColorRect.new()
	tube.color = Color("#C9B8E8")
	tube.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tube)
	var cap := ColorRect.new()
	cap.color = Color("#9B7FD1")
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tube.add_child(cap)
	# Sizes are applied once the nodes are in the tree; a plain Control parent
	# leaves them alone.
	tube.size = Vector2(24, 80)
	cap.position = Vector2.ZERO
	cap.size = Vector2(24, 14)
	tube.position = Vector2(TUBE_START_X, 92.0)
	return tube


func _show_analyzing() -> void:
	if _phase != Phase.ANIMATING:
		return
	content.add_child(UI.label("Aspirating… analyzing…"))
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 28
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(bar)
	var tween := create_tween()
	track_tween(bar, tween)
	tween.tween_property(bar, "value", 100.0, 2.5)
	tween.finished.connect(_show_report)


func _show_report() -> void:
	if _phase != Phase.ANIMATING:
		return
	_phase = Phase.REPORT
	clear_body()
	_build_art()
	var sex := str(_case.get("sex", "F"))
	var cbc: Dictionary = _case.get("cbc", {})
	content.add_child(UI.label("Adult · Age %d · %s" % [int(_case.get("age", 0)), sex]))
	content.add_child(UI.label(str(_case.get("vignette", ""))))
	content.add_child(ReportTable.build("cbc", cbc, sex))
	var authored := not String(_case.get("id", "")).is_empty()
	content.add_child(UI.label(SMEAR_AUTHORED if authored else SMEAR_SYNTHETIC))
	var action := AnalyzerLogic.review_action(bool(_case.get("spurious", false)), authored)
	var question := {
		"stem": STEM,
		"choices": CHOICES.duplicate(),
		"answer": int(ACTION_INDEX[action]),
		"image": null,
		"explanation": _explanation(action),
		"source": str(_case.get("source", "")),
	}
	var panel := ask(question)
	panel.answered.connect(_after_answer)
	panel.next_pressed.connect(_load_next_sample)


func _explanation(action: String) -> String:
	match action:
		"smear":
			return EXPLAIN_SMEAR
		"investigate":
			var steps: Array = _case.get("steps", [])
			if steps.is_empty():
				return EXPLAIN_INVESTIGATE
			return EXPLAIN_INVESTIGATE + str((steps[0] as Dictionary).get("explanation", ""))
		_:
			return EXPLAIN_RELEASE


func _after_answer(_correct: bool, _chosen: int) -> void:
	if _report_answered or _phase != Phase.REPORT:
		return
	_report_answered = true
	var slide_id := _smear_slide_id()
	if not slide_id.is_empty():
		_slide_button = UI.button("Make a smear for the microscope", func(): _place_slide(slide_id), "SecondaryButton")
		content.add_child(_slide_button)
	content.add_child(UI.button("Next sample", _load_next_sample))


## First pending smear finding that the microscope can actually prepare.
func _smear_slide_id() -> String:
	var smear: Array = _case.get("smear", [])
	for entry in smear:
		var id := str(entry)
		if id == "normal_rbc":
			continue
		var entity: Dictionary = Content.morph.get(id, {})
		if str(entity.get("category", "")) == "stain":
			continue
		return id
	return ""


func _place_slide(id: String) -> void:
	if _slide_placed:
		return
	_slide_placed = true
	if _slide_button != null and is_instance_valid(_slide_button):
		_slide_button.disabled = true
	session["slide_morph"] = id
	UI.toast(self, "Slide placed at the microscope.")


func _cell(text_value: String, bold: bool = false) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 24
	label.text = "[b]%s[/b]" % text_value if bold else text_value
	return label
