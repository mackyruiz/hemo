extends Control
## Last-run Westgard interpretation, release decision, and error type.

signal finished(result: Dictionary)

const LABELS := {
	"": "No violation", "1_2s": "1-2s (warning only)", "1_3s": "1-3s",
	"2_2s": "2-2s", "R_4s": "R-4s", "4_1s": "4-1s", "10_x": "10-x"
}
const RULE_EXPLANATIONS := {
	"": "Neither control level triggers a Westgard rule on the most recent run; the run may be accepted.",
	"1_2s": "One control exceeds 2 SD; this is a warning alone, not a rejection rule.",
	"1_3s": "One control exceeds 3 SD; reject the run because this rule suggests random error.",
	"2_2s": "Two control results exceed 2 SD on the same side, within a run or across consecutive runs; this suggests systematic error.",
	"R_4s": "The two control levels exceed opposite 2 SD limits within the same run; this suggests random error.",
	"4_1s": "Four consecutive results for one level exceed 1 SD on the same side; this suggests systematic error.",
	"10_x": "Ten consecutive results for one level are on the same side of the mean; this suggests systematic error."
}

var _rng := RandomNumberGenerator.new()
var _content: VBoxContainer
var _question_host: VBoxContainer
var _questions: Array[Dictionary] = []
var _index: int = 0
var _correct: int = 0
var _xp: int = 0
var _answered: bool = false
var _completed: bool = false


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var data: Dictionary = QcGenerator.generate(String(task["scenario"]), _rng)
	var rule: String = String(data["expected_rule"])
	var page: Array = UI.page("Quality control", false)
	add_child(page[0])
	_content = page[1]
	_content.add_child(UI.label("%s · %s" % [String(data["analyte"]), String(data["unit"])]))
	for level in data["levels"]:
		_content.add_child(UI.label("%s: mean %s · SD %s" % [String(level["name"]), str(level["mean"]), str(level["sd"])], "MutedLabel"))
	var chart := LJChart.new()
	_content.add_child(chart)
	chart.setup(data)
	_question_host = UI.vbox()
	_question_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_question_host)
	_build_questions(rule)
	_show_question()


func _build_questions(rule: String) -> void:
	var distractors: Array[String] = []
	for key in LABELS:
		if String(key) != rule:
			distractors.append(String(LABELS[key]))
	for i in range(distractors.size() - 1, 0, -1):
		var other: int = _rng.randi_range(0, i)
		var previous: String = distractors[i]
		distractors[i] = distractors[other]
		distractors[other] = previous
	var choices: Array[String] = [String(LABELS[rule])]
	for i in range(3):
		choices.append(distractors[i])
	var source_id: String = String(Content.generated_sources.get("qc:westgard", ""))
	_questions.append({"stem": "Which is the highest-priority (most severe) Westgard rule violated on the most recent run?", "choices": choices, "answer": 0, "image": null, "source": source_id, "explanation": String(RULE_EXPLANATIONS[rule]) + " Multiple rules can coexist; select the highest-priority rule in this exercise: 1-3s > R-4s > 2-2s > 4-1s > 10-x > 1-2s. A 1-2s warning alone does not reject the run."})
	var reject: bool = rule != "" and rule != "1_2s"
	_questions.append({
		"stem": "What should you do?",
		"choices": ["Accept the run and report patient results", "Reject the run, hold patient results, and troubleshoot"],
		"answer": 1 if reject else 0, "image": null, "source": source_id,
		"explanation": ("Do not release patient results until the QC failure is resolved. " if reject else "With no rejection rule present, the run can be accepted. ") + String(RULE_EXPLANATIONS[rule])
	})
	if reject:
		var error: String = Westgard.error_type(rule)
		_questions.append({"stem": "What type of error does this suggest?", "choices": ["Random error", "Systematic error"], "answer": 0 if error == "random" else 1, "image": null, "source": source_id, "explanation": String(RULE_EXPLANATIONS[rule])})


func _show_question() -> void:
	for child in _question_host.get_children():
		_question_host.remove_child(child)
		child.queue_free()
	_answered = false
	_question_host.add_child(UI.label("Question %d/%d" % [_index + 1, _questions.size()], "MutedLabel"))
	var panel := QuestionPanel.new()
	_question_host.add_child(panel)
	panel.setup(_questions[_index], {"show_feedback": true, "rng": _rng})
	panel.answered.connect(func(correct: bool, _chosen: int):
		if _answered:
			return
		_answered = true
		Progress.record_topic_only("qc", correct)
		if correct:
			_correct += 1
			_xp += XpRules.XP_PER_CORRECT_PER_DIFFICULTY
	)
	panel.next_pressed.connect(func():
		if not _answered or _completed:
			return
		_index += 1
		if _index >= _questions.size():
			_completed = true
			finished.emit({"correct": _correct, "total": _questions.size(), "xp": _xp})
		else:
			_show_question()
	)
