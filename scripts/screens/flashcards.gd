extends Control

var _content: VBoxContainer
var _queue: Array[Dictionary] = []
var _shown: int = 0
var _got: int = 0
var _again: int = 0
var _revealed: bool = false


func _ready() -> void:
	var p: Array = UI.page("Flashcards")
	add_child(p[0])
	_content = p[1]
	_show_decks()


func _clear() -> void:
	for child in _content.get_children():
		child.queue_free()


func _show_decks() -> void:
	_clear()
	var cells: Array[Dictionary] = Flashcards.cell_cards(Content.morph, Content.photos_by_morph)
	var terms: Array[Dictionary] = Flashcards.term_cards(Content.glossary)
	var all: Array[Dictionary] = cells.duplicate()
	all.append_array(terms)
	var state: Dictionary = Progress.data.get("cards", {})
	var now: int = int(Time.get_unix_time_from_system())
	_content.add_child(UI.button("Cells (%s due)" % _count(cells, state, now), func(): _open(cells)))
	_content.add_child(UI.button("Terms (%s due)" % _count(terms, state, now), func(): _open(terms)))
	_content.add_child(UI.button("All decks (%s due)" % _count(all, state, now), func(): _open(all)))
	_content.add_child(UI.label("Rate yourself honestly: Again brings a card back soon; Got it spaces it out.", "MutedLabel"))


func _count(cards: Array[Dictionary], state: Dictionary, now: int) -> String:
	var due: int = 0
	var unseen: int = 0
	for card in cards:
		var entry: Dictionary = state.get(card["key"], {})
		if entry.is_empty():
			unseen += 1
		elif Leitner.is_due(entry, now):
			due += 1
	var total: int = due + unseen
	return "20+" if total > Flashcards.SESSION_SIZE else str(total)


func _open(cards: Array[Dictionary]) -> void:
	_shown = 0
	_got = 0
	_again = 0
	_revealed = false
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var state: Dictionary = Progress.data.get("cards", {})
	var now: int = int(Time.get_unix_time_from_system())
	var session: Array[Dictionary] = Flashcards.session(cards, state, now, rng)
	if session.is_empty():
		_show_empty(cards, state, now, rng)
		return
	_queue = session
	_render_card()


func _show_empty(cards: Array[Dictionary], state: Dictionary, now: int, rng: RandomNumberGenerator) -> void:
	_clear()
	var base: String = "Nothing due in this deck."
	var next: int = Flashcards.next_due(cards, state)
	if next >= 0:
		var hours: int = int(float(next - now) / 3600.0)
		var when: String = "in %d hours" % hours if hours < 48 else "in %d days" % int(hours / 24)
		base = "Nothing due in this deck. Next card due %s." % when
	_content.add_child(UI.label(base, "MutedLabel"))
	_content.add_child(UI.button("Study anyway (shuffled)", func(): _study_shuffled(cards, rng)))
	_content.add_child(UI.button("Back to decks", func(): _show_decks(), "SecondaryButton"))


func _study_shuffled(cards: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	_shown = 0
	_got = 0
	_again = 0
	_revealed = false
	_queue = Flashcards.shuffled_all(cards, rng)
	_render_card()


func _render_card() -> void:
	_clear()
	if _queue.is_empty():
		_content.add_child(UI.label("Session complete — %d got it, %d again." % [_got, _again], "MutedLabel"))
		_content.add_child(UI.button("Back to decks", func(): _show_decks(), "SecondaryButton"))
		return
	var card: Dictionary = _queue[0]
	var left: String = "Card %d · %d left" % [_shown + 1, _queue.size()]
	_content.add_child(UI.label(left, "MutedLabel"))
	var box: Control = UI.card()
	_content.add_child(box)
	var column: VBoxContainer = UI.vbox()
	box.add_child(column)
	if str(card["kind"]) == "cell":
		var entity: Dictionary = Content.morph.get(str(card["id"]), {})
		var photos: Array = Content.photos_by_morph.get(str(card["id"]), [])
		column.add_child(PhotoView.block(photos[0], 320))
		column.add_child(UI.label("Name this cell or finding."))
		if _revealed:
			column.add_child(UI.label(str(entity.get("name", card["id"])), "TitleLabel"))
			column.add_child(UI.label(str(entity.get("features", ""))))
			column.add_child(UI.label("Associations: " + "; ".join(entity.get("associations", []))))
			column.add_child(UI.source_link(str(entity.get("source", ""))))
	else:
		var term_data: Dictionary = _term(str(card["id"]))
		column.add_child(UI.label(str(term_data.get("term", card["id"])), "TitleLabel"))
		column.add_child(UI.label("Define this term."))
		if _revealed:
			column.add_child(UI.label(str(term_data.get("definition", ""))))
			column.add_child(UI.source_link(str(term_data.get("source", ""))))
	if not _revealed:
		column.add_child(UI.button("Show answer", func(): _reveal()))
		return
	var row: HBoxContainer = UI.hbox()
	column.add_child(row)
	row.add_child(UI.button("Again", func(): _grade(false), "SecondaryButton"))
	row.add_child(UI.button("Got it", func(): _grade(true)))


func _reveal() -> void:
	_revealed = true
	_render_card()


func _grade(known: bool) -> void:
	var card: Dictionary = _queue.pop_front()
	Progress.record_card(str(card["key"]), known)
	if known:
		_got += 1
	else:
		_again += 1
		_queue.append(card)
	_shown += 1
	_revealed = false
	_render_card()


func _term(id: String) -> Dictionary:
	for value in Content.glossary:
		if value is Dictionary and str(value.get("id", "")) == id:
			return value
	return {}
