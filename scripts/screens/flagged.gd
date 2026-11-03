extends Control

var _content: VBoxContainer


func _ready() -> void:
	var p: Array = UI.page("Flagged questions")
	add_child(p[0])
	_content = p[1]
	_build()


func _build() -> void:
	for child in _content.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = Progress.flagged()
	if entries.is_empty():
		_content.add_child(UI.label("No flagged questions yet. Tap “Flag for review” on any question to save it here.", "MutedLabel"))
		return
	for entry in entries:
		var key: String = str(entry["key"])
		var q: Dictionary = entry.get("q", {})
		var case_id: String = str(q.get("case_id", ""))
		var topic_id: String = str(q.get("topic", ""))
		var topic: String = "CASE" if not case_id.is_empty() else str(Topics.NAMES.get(topic_id, topic_id.to_upper()))
		var card := UI.card()
		var column := UI.vbox()
		_content.add_child(card)
		card.add_child(column)
		column.add_child(UI.label(topic, "MutedLabel"))
		var stem: String = str(q.get("stem", ""))
		if stem.length() > 140:
			stem = stem.substr(0, 140) + "…"
		column.add_child(UI.label(stem))
		var row := UI.hbox()
		column.add_child(row)
		row.add_child(UI.button("Review", func(): Nav.go("flagged_question", {"key": key})))
		row.add_child(UI.button("Remove", func(): _remove(key), "SecondaryButton"))


func _remove(key: String) -> void:
	Progress.unflag(key)
	_build()
