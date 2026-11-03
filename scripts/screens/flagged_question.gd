extends Control

var _key: String = ""


func setup(params: Dictionary) -> void:
	_key = str(params.get("key", ""))


func _ready() -> void:
	var p: Array = UI.page("Review flagged question")
	add_child(p[0])
	var content: VBoxContainer = p[1]
	var entry: Dictionary = {}
	for candidate in Progress.flagged():
		if str(candidate["key"]) == _key:
			entry = candidate
			break
	if entry.is_empty():
		content.add_child(UI.label("This question is no longer flagged.", "MutedLabel"))
		return
	var snapshot: Dictionary = entry.get("q", {})
	var question: Dictionary = Content.questions_by_id.get(_key, snapshot)
	var case_id: String = str(snapshot.get("case_id", ""))
	if not case_id.is_empty() and Content.cases_by_id.has(case_id):
		var case_data: Dictionary = Content.cases_by_id[case_id]
		var kind: String = "cbc" if case_data.has("cbc") else "coag"
		var vignette := UI.card()
		var text := UI.vbox()
		vignette.add_child(text)
		text.add_child(UI.label("Adult patient · Age %d · %s" % [int(case_data["age"]), String(case_data["sex"])], "MutedLabel"))
		text.add_child(UI.label(String(case_data["vignette"])))
		content.add_child(vignette)
		var results: Dictionary = case_data["cbc"] if kind == "cbc" else case_data["results"]
		content.add_child(ReportTable.build(kind, results, String(case_data["sex"])))
	var panel := QuestionPanel.new()
	content.add_child(panel)
	panel.setup(question, {"show_feedback": true, "allow_hint": false, "flag": {"key": _key, "case_id": case_id}})
	panel.next_pressed.connect(func(): Nav.back())
