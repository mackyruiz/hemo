extends GutTest

## Every waste item and every container the safety bench can show has its own drawing,
## and a kind listed in SortArt but missing from the painter fails here rather than
## rendering an invisible chip.


func test_every_waste_item_and_container_has_a_drawing() -> void:
	var seen: Array[String] = []
	for item: Dictionary in SafetySort.ITEMS:
		var art_kind: String = String(item.get("art", ""))
		assert_true(SortArt.has_kind(art_kind), "%s needs a drawing" % String(item["name"]))
		assert_false(seen.has(art_kind), "the drawing %s would repeat" % art_kind)
		seen.append(art_kind)
	assert_eq(SafetySort.BIN_ART.size(), SafetySort.BINS.size(), "one drawing per container")
	for kind: String in SafetySort.BIN_ART:
		assert_true(SortArt.BIN_KINDS.has(kind), "%s must be a container drawing" % kind)


func test_every_declared_kind_paints() -> void:
	for kind in SortArt.ITEM_KINDS + SortArt.BIN_KINDS:
		var art := SortArt.make(String(kind), ThemeBuilder.PRIMARY)
		add_child_autofree(art)
		art.size = Vector2(48, 48)
		await wait_process_frames(1)
		assert_true(art.painted, "%s should draw something" % String(kind))


func test_an_unknown_kind_paints_nothing() -> void:
	var art := SortArt.make("mystery", ThemeBuilder.PRIMARY)
	add_child_autofree(art)
	art.size = Vector2(48, 48)
	await wait_process_frames(1)
	assert_false(art.painted, "an unknown kind must not claim a drawing")
	assert_false(SortArt.has_kind("mystery"))
	assert_false(SortArt.has_kind(""))
