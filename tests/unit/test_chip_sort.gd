extends GutTest

## The sort keeps items (neutral tags in a scrolling tray) apart from containers (tinted
## targets pinned in a dock), and a picked-up item lands back where it came from.

const BINS := ["Alpha bin", "Beta bin"]
const CHIPS := [
	{"name": "a", "bin": 0},
	{"name": "b", "bin": 1},
	{"name": "c", "bin": 0},
]
# The same control with drawn items and drawn targets; the art-less CHIPS fixture above
# is the coagulation-sort path.
const ART_CHIPS := [
	{"name": "a", "bin": 0, "art": "needle"},
	{"name": "b", "bin": 1, "art": "gauze"},
	{"name": "c", "bin": 0, "art": "slide"},
]
const ART_BINS := ["sharps", "biohazard_bag"]

var _sort: ChipSort


func before_each() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_sort = ChipSort.new()
	# The app theme (ChipButton/BinButton variations) is what the control colours against.
	_sort.theme = ThemeBuilder.build(false)
	add_child_autofree(_sort)
	_sort.setup("Sort things", "Tap an item, then a container.", BINS, CHIPS, rng, "")
	await wait_process_frames(2)


## Tray order as shuffled slots, so text prefixes never hide a reordering bug.
func _tray_ranks() -> Array[int]:
	var ranks: Array[int] = []
	for child in _sort._tray.get_children():
		ranks.append(int(child.get_meta("rank")))
	return ranks


func _chip_with_rank(rank: int) -> int:
	for index in range(_sort._buttons.size()):
		if int(_sort._buttons[index].get_meta("rank")) == rank:
			return index
	return -1


func test_placing_moves_the_item_into_that_container() -> void:
	var tray_before: int = _sort._tray.get_child_count()
	_sort._select_chip(0)
	_sort._place_chip(0)
	assert_eq(_sort._buttons[0].get_parent(), _sort._bin_hosts[0], "the item leaves the tray")
	assert_eq(_sort._tray.get_child_count(), tray_before - 1)
	assert_eq(_sort._bin_hosts[0].get_child_count(), 1)
	assert_eq(_sort._buttons[0].text, ThemeBuilder.sort_glyph(0) + " a", "the item carries its container glyph")
	assert_eq(_sort._dock_buttons[0].text, "%s %s\n1 placed" % [ThemeBuilder.sort_glyph(0), BINS[0]])


func test_tapping_a_placed_item_returns_it_to_its_own_slot() -> void:
	var order := _tray_ranks()
	var middle := _chip_with_rank(1)
	_sort._select_chip(middle)
	_sort._place_chip(1)
	assert_ne(_tray_ranks(), order, "the item should leave the tray first")
	_sort._select_chip(middle)
	assert_eq(_sort._buttons[middle].get_parent(), _sort._tray, "the item returns to the tray")
	assert_eq(_tray_ranks(), order, "the item returns to its shuffled slot, not the end")
	assert_eq(_sort._buttons[middle].text, "▸ " + String(CHIPS[middle]["name"]), "the returned item is the held one")
	assert_eq(_sort._bin_hosts[1].get_child_count(), 0)


func test_placing_with_nothing_held_moves_nothing() -> void:
	var tray_before: int = _sort._tray.get_child_count()
	_sort._place_chip(0)
	assert_eq(_sort._tray.get_child_count(), tray_before)
	assert_eq(_sort._bin_hosts[0].get_child_count(), 0)
	assert_eq(_sort._check_button.text, "Check — 0 of 3 placed")
	assert_string_contains(_sort._banner.text, "first")


func test_check_reports_one_result_per_chip_in_chip_order() -> void:
	watch_signals(_sort)
	_sort._select_chip(0)  # a belongs in Alpha bin: correct
	_sort._place_chip(0)
	_sort._select_chip(1)  # b belongs in Beta bin: placed in the wrong one
	_sort._place_chip(0)
	# chip c is never placed
	_sort._check()
	assert_signal_emitted(_sort, "checked")
	var results: Array = get_signal_parameters(_sort, "checked", 0)[0]
	assert_eq(results.size(), CHIPS.size(), "one result per chip")
	assert_eq(results[0], true, "a chip in its correct bin is true")
	assert_eq(results[1], false, "a chip in the wrong bin is false")
	assert_eq(results[2], false, "an unplaced chip is false")
	assert_string_contains(_sort._summary.text, "Checked: 1 of 3 correct.")


func test_containers_are_tinted_apart_and_items_stay_neutral() -> void:
	var seen: Array[Color] = []
	for bin_button in _sort._dock_buttons:
		var bg: Color = bin_button.get_theme_stylebox("normal").bg_color
		for other in seen:
			assert_ne(bg, other, "no two containers may share a fill")
		assert_ne(bg, ThemeBuilder.SURFACE, "a container must not read like an item tag")
		seen.append(bg)
	for button in _sort._buttons:
		assert_eq(button.theme_type_variation, "ChipButton")
		assert_eq(button.get_theme_stylebox("normal").bg_color, ThemeBuilder.SURFACE, "item tags stay neutral")
		assert_false(button.toggle_mode, "items are not toggles")


## The same control built with drawn items and drawn container targets.
func _art_sort() -> ChipSort:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var sort := ChipSort.new()
	sort.theme = ThemeBuilder.build(false)
	add_child_autofree(sort)
	sort.setup("Sort things", "Tap an item, then a container.", BINS, ART_CHIPS, rng, "", "item", "container", ART_BINS)
	await wait_process_frames(2)
	return sort


func _arts(button: Button) -> Array[SortArt]:
	var found: Array[SortArt] = []
	for child in button.get_children():
		if child is SortArt:
			found.append(child as SortArt)
	return found


func test_item_chips_carry_their_own_drawing() -> void:
	var sort: ChipSort = await _art_sort()
	for index in range(ART_CHIPS.size()):
		var arts := _arts(sort._buttons[index])
		assert_eq(arts.size(), 1, "one drawing per item chip")
		var art: SortArt = arts[0]
		assert_eq(art.kind, String(ART_CHIPS[index]["art"]), "each chip shows its own drawing")
		assert_eq(art.offset_right - art.offset_left, float(ThemeBuilder.icon_px(sort._buttons[index].get_theme_font_size("font_size"))), "the drawing scales with the label beside it")
		assert_gte(sort._buttons[index].get_theme_stylebox("normal").content_margin_left, art.offset_right, "the label starts clear of the drawing")
	sort._select_chip(0)
	sort._place_chip(0)
	var moved: Button = sort._buttons[0]
	assert_eq(_arts(moved).size(), 1, "the drawing rides along with the placed item")
	assert_eq(moved.get_parent(), sort._bin_hosts[0])


func test_held_item_lightens_its_drawing() -> void:
	var sort: ChipSort = await _art_sort()
	sort._select_chip(1)
	assert_eq(sort._icons[1].ink, Color.WHITE, "outlines flip to white on the dark held chip")
	assert_eq(sort._icons[0].ink, ThemeBuilder.TEXT, "only the held chip's drawing changes")
	sort._select_chip(1)
	assert_eq(sort._icons[1].ink, ThemeBuilder.TEXT, "putting the item down darkens the outlines again")


func test_container_targets_show_their_container_drawing() -> void:
	var sort: ChipSort = await _art_sort()
	for index in range(ART_BINS.size()):
		var dock_button: Button = sort._dock_buttons[index]
		var arts := _arts(dock_button)
		assert_eq(arts.size(), 1, "one drawing per container target")
		var art: SortArt = arts[0]
		assert_eq(art.kind, ART_BINS[index], "each target shows its own container")
		assert_eq(art.tint, ThemeBuilder.sort_tint(index), "a container is drawn in its own tint")
		assert_gte(dock_button.get_theme_stylebox("normal").content_margin_left, art.offset_right, "the label starts clear of the drawing")


func test_item_drawings_never_use_a_container_tint() -> void:
	var sort: ChipSort = await _art_sort()
	for index in range(ART_CHIPS.size()):
		var arts := _arts(sort._buttons[index])
		assert_eq(arts.size(), 1)
		assert_false(ThemeBuilder.SORT_TINTS.has(arts[0].tint), "an item drawing may not wear a container colour")
		assert_false(ThemeBuilder.SORT_TINTS.has(arts[0].ink), "item outlines are never a container colour")
