extends Control

var _results: Dictionary = {}


func setup(params: Dictionary) -> void:
	_results = params.get("results", {})


func _ready() -> void:
	var page: Array = UI.page("Exam report")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("Overall: %.0f%%" % (float(_results.get("score", 0.0)) * 100.0), "TitleLabel"))
	content.add_child(UI.label("%d / %d correct" % [int(_results.get("correct", 0)), int(_results.get("total", 100))]))
	var seconds: int = int(round(float(_results.get("duration_s", 0.0))))
	content.add_child(UI.label("Time used: %02d:%02d" % [seconds / 60, seconds % 60]))
	content.add_child(UI.label("Practice benchmark only — not an official pass predictor.", "MutedLabel"))
	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 12)
	table.add_theme_constant_override("v_separation", 12)
	for heading in ["Topic", "Correct", "%"]:
		table.add_child(UI.label(heading, "MutedLabel"))
	var by_topic: Dictionary = _results.get("by_topic", {})
	for topic in Topics.NAMES:
		var counts: Dictionary = by_topic.get(topic, {})
		var correct: int = int(counts.get("correct", 0))
		var total: int = int(counts.get("total", 0))
		var percent: float = float(correct) * 100.0 / float(total) if total > 0 else 0.0
		table.add_child(UI.label(Topics.NAMES[topic]))
		table.add_child(UI.label("%d/%d" % [correct, total]))
		table.add_child(UI.label("%.0f%%" % percent))
	content.add_child(table)
	content.add_child(UI.label("Review missed items", "TitleLabel"))
	var missed: int = 0
	var items: Array = _results.get("items", [])
	for value in items:
		var result: Dictionary = value
		if bool(result.get("correct", false)):
			continue
		missed += 1
		content.add_child(_missed_card(result))
	if missed == 0:
		content.add_child(UI.label("✓ No missed items. Well done!"))
	content.add_child(UI.button("Back to lab", func(): Nav.go("hub")))


func _missed_card(result: Dictionary) -> PanelContainer:
	var card := UI.card()
	var v := UI.vbox(10)
	card.add_child(v)
	var item: Dictionary = result.get("item", {})
	var choices: Array = item.get("choices", [])
	var chosen: int = int(result.get("chosen", -1))
	var answer: int = int(item.get("answer", -1))
	v.add_child(UI.label(str(item.get("stem", result.get("id", "")))))
	var chosen_text: String = str(choices[chosen]) if chosen >= 0 and chosen < choices.size() else "No answer"
	var correct_text: String = str(choices[answer]) if answer >= 0 and answer < choices.size() else "—"
	var wrong := UI.label("✗ Your answer: " + chosen_text)
	wrong.add_theme_color_override("font_color", ThemeBuilder.ERROR)
	v.add_child(wrong)
	var key := UI.label("✓ Correct answer: " + correct_text)
	key.add_theme_color_override("font_color", ThemeBuilder.SUCCESS)
	v.add_child(key)
	v.add_child(UI.label(str(item.get("explanation", "")), "MutedLabel"))
	var link: Button = UI.source_link(str(item.get("source", "")))
	if link != null:
		v.add_child(link)
	return card
