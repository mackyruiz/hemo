extends Control
## No feedback until the report; time advances only with processed frames.

var _content: VBoxContainer
var _body: VBoxContainer
var _timer: Label
var _counter: Label
var _exam: AdaptiveExam
var _started: bool = false
var _finished: bool = false
var _elapsed: float = 0.0
var _item_elapsed: float = 0.0
var _leave_dialog: ConfirmationDialog
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = Time.get_ticks_usec()
	var page: Array = UI.page("Board Sim")
	add_child(page[0])
	_content = page[1]
	var card := UI.card()
	var intro := UI.vbox()
	card.add_child(intro)
	intro.add_child(UI.label("Mock MLT exam", "TitleLabel"))
	intro.add_child(UI.label("100 questions · 150 minutes"))
	intro.add_child(UI.label("One question at a time, with no going back and no feedback until the end. Difficulty adapts to your answers, like the ASCP CAT."))
	intro.add_child(UI.label("This is a practice benchmark, not an official exam or pass predictor. The timer pauses while the browser tab is backgrounded.", "MutedLabel"))
	_content.add_child(card)
	_content.add_child(UI.button("Start exam", _start))
	_leave_dialog = UI.confirm_dialog("Leave Board Sim?", "Abandon exam? It will not be scored.", "Abandon exam", "Keep going")
	_leave_dialog.confirmed.connect(func():
		_started = false
		Nav.force_back()
	)
	add_child(_leave_dialog)


func _start() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var recent_ids: Array = []
	var history: Array = Progress.data.get("exams", [])
	if not history.is_empty():
		var previous: Dictionary = history[-1]
		recent_ids = previous.get("items", [])
	_exam = AdaptiveExam.new(Content.as_dict(), _rng, recent_ids)
	_elapsed = 0.0
	_item_elapsed = 0.0
	_started = true
	var header := UI.hbox()
	_counter = UI.label("Question 1 of 100")
	_timer = UI.label("150:00")
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_counter)
	header.add_child(_timer)
	_content.add_child(header)
	_body = UI.vbox()
	_content.add_child(_body)
	_show_next()


func _process(delta: float) -> void:
	if not _started or _finished:
		return
	_elapsed += delta
	_item_elapsed += delta
	var remaining: int = maxi(0, int(ceil(float(AdaptiveExam.DURATION_S) - _elapsed)))
	_timer.text = "%02d:%02d" % [remaining / 60, remaining % 60]
	if remaining <= 0:
		_elapsed = float(AdaptiveExam.DURATION_S)
		_exam.mark_timeout()
		_finish()


func _show_next() -> void:
	if _finished:
		return
	if _exam.is_done():
		_finish()
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var item: Dictionary = _exam.next_item()
	_counter.text = "Question %d of 100" % (_exam.count_answered() + 1)
	_item_elapsed = 0.0
	var panel := QuestionPanel.new()
	panel.setup(item, {"show_feedback": false, "allow_hint": false, "rng": _rng, "flag": {"key": str(item["id"])}})
	panel.answered.connect(_answered)
	_body.add_child(panel)
	# Locate the page's scroll container without relying on internal node names.
	_scroll_to_top(self)


func _scroll_to_top(node: Node) -> void:
	if node is ScrollContainer:
		(node as ScrollContainer).set_deferred("scroll_vertical", 0)
		return
	for child in node.get_children():
		_scroll_to_top(child)


func _answered(correct: bool, chosen: int) -> void:
	if _finished:
		return
	_exam.answer(correct, _item_elapsed, chosen)
	_show_next.call_deferred()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_started = false
	var results: Dictionary = _exam.results()
	results["duration_s"] = _elapsed
	var by_topic: Dictionary = results.get("by_topic", {})
	var percentages: Dictionary = {}
	for topic in by_topic:
		var counts: Dictionary = by_topic[topic]
		var total: int = int(counts.get("total", 0))
		percentages[topic] = float(counts.get("correct", 0)) / float(total) if total > 0 else 0.0
	var ids: Array[String] = []
	var items: Array = results.get("items", [])
	for value in items:
		var result: Dictionary = value
		ids.append(str(result["id"]))
	Progress.record_exam({
		"ts": int(Time.get_unix_time_from_system()),
		"score": float(results.get("score", 0.0)),
		"by_topic": percentages,
		"duration_s": _elapsed,
		"items": ids,
	})
	Progress.add_xp(XpRules.XP_EXAM_COMPLETE)
	for value in items:
		var result: Dictionary = value
		var item: Dictionary = result.get("item", {})
		Progress.record_item(str(result["id"]), str(item.get("topic", "lab")), bool(result.get("correct", false)))
	Nav.replace("exam_report", {"results": results})


func can_leave() -> bool:
	if not _started or _finished:
		return true
	UI.popup_confirm(_leave_dialog)
	return false
