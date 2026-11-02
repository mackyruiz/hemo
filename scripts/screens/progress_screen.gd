extends Control

const TOPICS := {
	"phys": "Physiology", "rbc": "RBC disorders", "wbc": "WBC disorders",
	"plt": "Platelet disorders", "lab": "Lab testing & morphology",
	"hemo": "Hemostasis", "qc": "QC & lab operations",
}


func _ready() -> void:
	var page: Array = UI.page("My Progress")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("Topic mastery", "TitleLabel"))
	content.add_child(UI.label("Based on your last 20 attempts in each topic.", "MutedLabel"))
	for topic in TOPICS:
		var card := UI.card()
		var v := UI.vbox(8)
		card.add_child(v)
		v.add_child(UI.label(TOPICS[topic]))
		var attempts: int = Progress.attempts(topic)
		var mastery: float = Progress.mastery(topic)
		if attempts == 0:
			v.add_child(UI.label("— · no attempts yet", "MutedLabel"))
		else:
			var bar := ProgressBar.new()
			bar.max_value = 100.0
			bar.value = mastery * 100.0
			bar.custom_minimum_size.y = 32
			v.add_child(bar)
			v.add_child(UI.label("%d attempts" % attempts, "MutedLabel"))
		content.add_child(card)

	content.add_child(UI.label("%d items due now" % Progress.due_count()))
	var stats: Dictionary = Progress.data.get("stats", {})
	content.add_child(UI.label("%d shifts completed" % int(stats.get("shifts_completed", 0))))
	var exams: Array = Progress.data.get("exams", [])
	content.add_child(UI.label("Readiness: " + ("On track" if _on_track(exams) else "Keep practicing"), "TitleLabel"))
	content.add_child(UI.label("Practice benchmark only — not an official pass predictor.", "MutedLabel"))
	content.add_child(UI.label("Mock exam history", "TitleLabel"))
	if exams.is_empty():
		content.add_child(UI.label("No mock exams yet. Try Board Sim when you are ready.", "MutedLabel"))
	else:
		for i in range(exams.size() - 1, -1, -1):
			var exam: Dictionary = exams[i]
			var date: Dictionary = Time.get_datetime_dict_from_unix_time(int(exam.get("ts", 0)))
			var stamp := "%04d-%02d-%02d" % [date["year"], date["month"], date["day"]]
			var card := UI.card()
			card.add_child(UI.label("%s · %.0f%%" % [stamp, float(exam.get("score", 0.0)) * 100.0]))
			content.add_child(card)


func _on_track(exams: Array) -> bool:
	if exams.size() < 2:
		return false
	for i in range(exams.size() - 2, exams.size()):
		var exam: Dictionary = exams[i]
		if float(exam.get("score", 0.0)) < 0.75:
			return false
		var by_topic: Dictionary = exam.get("by_topic", {})
		for topic in TOPICS:
			if float(by_topic.get(topic, 0.0)) < 0.60:
				return false
	return true
