extends GutTest

## Every incident the safety bench can show has its own drawing; a kind listed in
## ScenarioArt but missing from the painter fails here rather than leaving the card
## with an empty box above the vignette.


func test_every_declared_kind_paints() -> void:
	for kind: String in ScenarioArt.KINDS:
		var art := ScenarioArt.make(kind)
		add_child_autofree(art)
		art.size = Vector2(300, 200)
		await wait_process_frames(1)
		assert_true(art.painted, "%s should draw something" % kind)


func test_an_unknown_kind_paints_nothing() -> void:
	var art := ScenarioArt.make("mystery")
	add_child_autofree(art)
	art.size = Vector2(300, 200)
	await wait_process_frames(1)
	assert_false(art.painted, "an unknown kind must not claim a drawing")
	assert_false(ScenarioArt.has_kind("mystery"))
	assert_false(ScenarioArt.has_kind(""))
