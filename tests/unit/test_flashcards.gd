extends GutTest


func test_session_orders_due_cards_before_unseen() -> void:
	var cards: Array[Dictionary] = [
		{"key": "term:a", "kind": "term", "id": "a"},
		{"key": "term:b", "kind": "term", "id": "b"},
		{"key": "term:c", "kind": "term", "id": "c"},
		{"key": "term:d", "kind": "term", "id": "d"},
	]
	var state: Dictionary = {
		"term:a": {"box": 2, "due": 200, "attempts": 1, "correct": 1},
		"term:b": {"box": 1, "due": 100, "attempts": 1, "correct": 0},
		"term:c": {"box": 1, "due": 300, "attempts": 1, "correct": 0}
	}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var session: Array[Dictionary] = Flashcards.session(cards, state, 250, rng)
	assert_eq(session.size(), 3)
	assert_eq(str(session[0]["key"]), "term:b")
	assert_eq(str(session[1]["key"]), "term:a")
	assert_eq(str(session[2]["key"]), "term:d")


func test_unseen_shuffle_is_deterministic_per_seed() -> void:
	var cards: Array[Dictionary] = []
	for i in range(6):
		cards.append({"key": "term:" + str(i), "kind": "term", "id": str(i)})
	var first: Array[Dictionary] = Flashcards.session(cards, {}, 0, _seeded(99))
	var second: Array[Dictionary] = Flashcards.session(cards, {}, 0, _seeded(99))
	assert_eq(first.size(), 6)
	for i in range(6):
		assert_eq(str(first[i]["key"]), str(second[i]["key"]))


func test_session_caps_at_twenty() -> void:
	var cards: Array[Dictionary] = []
	for i in range(25):
		cards.append({"key": "term:" + str(i), "kind": "term", "id": str(i)})
	assert_eq(Flashcards.session(cards, {}, 0, _seeded(3)).size(), 20)


func test_next_due_returns_earliest_seen_due() -> void:
	var cards: Array[Dictionary] = [
		{"key": "term:a", "kind": "term", "id": "a"},
		{"key": "term:b", "kind": "term", "id": "b"},
	]
	var state: Dictionary = {"term:b": {"box": 1, "due": 300}, "term:a": {"box": 2, "due": 120}}
	assert_eq(Flashcards.next_due(cards, state), 120)
	assert_eq(Flashcards.next_due(cards, {}), -1)


func test_cell_cards_sort_ids_and_prefix_keys() -> void:
	var cards: Array[Dictionary] = Flashcards.cell_cards({"z_cell": {}, "a_cell": {}, "no_photo": {}}, {"z_cell": [{}], "a_cell": [{}]})
	assert_eq(cards.size(), 2)
	assert_eq(str(cards[0]["key"]), "cell:a_cell")
	assert_eq(str(cards[1]["key"]), "cell:z_cell")


func _seeded(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
