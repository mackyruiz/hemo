class_name Flashcards
extends RefCounted

const SESSION_SIZE := 20


static func cell_cards(morph: Dictionary) -> Array[Dictionary]:
	var ids: Array[String] = []
	for id: String in morph:
		ids.append(id)
	ids.sort()
	var cards: Array[Dictionary] = []
	for id: String in ids:
		cards.append({"key": "cell:" + id, "kind": "cell", "id": id})
	return cards


static func term_cards(glossary: Array) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for value: Variant in glossary:
		if value is Dictionary:
			cards.append({"key": "term:" + str(value.get("id", "")), "kind": "term", "id": str(value.get("id", ""))})
	return cards


static func session(cards: Array[Dictionary], state: Dictionary, now: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var unseen: Array[Dictionary] = []
	for card in cards:
		var entry: Dictionary = state.get(card["key"], {})
		if entry.is_empty():
			unseen.append(card)
		elif Leitner.is_due(entry, now):
			due.append(card)
	due.sort_custom(func(a, b): return int(state[a["key"]]["due"]) < int(state[b["key"]]["due"]))
	for i in range(unseen.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, i)
		var swap: Dictionary = unseen[i]
		unseen[i] = unseen[other]
		unseen[other] = swap
	var out: Array[Dictionary] = due
	for card in unseen:
		if out.size() >= SESSION_SIZE:
			break
		out.append(card)
	return out


static func shuffled_all(cards: Array[Dictionary], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = cards.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, i)
		var swap: Dictionary = out[i]
		out[i] = out[other]
		out[other] = swap
	return out.slice(0, SESSION_SIZE)


static func next_due(cards: Array[Dictionary], state: Dictionary) -> int:
	var best: int = -1
	for card in cards:
		var entry: Dictionary = state.get(card["key"], {})
		if entry.is_empty():
			continue
		var due_time: int = int(entry.get("due", 0))
		if best < 0 or due_time < best:
			best = due_time
	return best
