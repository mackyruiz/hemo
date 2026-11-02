extends GutTest
## ScopeLogic: objective/oil/focus gating, zone blocking and seeded smear layout.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_reset_defaults_to_wright() -> void:
	var logic := ScopeLogic.new()
	logic.reset(_rng(2))
	assert_eq(logic.prep, "wright")
	assert_eq(logic.objective, 10)
	assert_false(logic.oil)
	assert_almost_eq(logic.stage_x, 20.0, 0.0001)
	assert_almost_eq(logic.focus, 50.0, 0.0001)
	assert_between(logic.focus_target, 20.0, 80.0)

	var kb := ScopeLogic.new()
	kb.reset(_rng(2), "kb")
	assert_eq(kb.prep, "kb")


func test_preparation_labels() -> void:
	assert_eq(ScopeLogic.PREPARATIONS.size(), 4)
	assert_eq(ScopeLogic.PREPARATIONS["wright"], "Peripheral blood — Wright–Giemsa")
	assert_eq(ScopeLogic.PREPARATIONS["retic"], "Reticulocytes — new methylene blue")
	assert_eq(ScopeLogic.PREPARATIONS["heinz"], "Heinz bodies — supravital stain")
	assert_eq(ScopeLogic.PREPARATIONS["kb"], "Kleihauer–Betke — acid elution")


func test_wright_requires_oil_before_100x() -> void:
	var rng := _rng(11)
	var logic := ScopeLogic.new()
	logic.reset(rng, "wright")

	assert_eq(logic.select_objective(100, rng), "Add a drop of immersion oil before rotating in the 100× oil objective.")
	assert_eq(logic.objective, 10)
	assert_false(logic.oil)

	assert_eq(logic.add_oil(), "")
	assert_true(logic.oil)

	assert_eq(logic.select_objective(100, rng), "")
	assert_eq(logic.objective, 100)
	assert_between(logic.focus_target, 5.0, 95.0)

	assert_eq(logic.select_objective(40, rng), "Oil is on the slide — don't swing the 40× high-dry objective through it. Use 10× or 100× oil.")
	assert_eq(logic.objective, 100)

	var target_before: float = logic.focus_target
	assert_eq(logic.select_objective(100, rng), "")
	assert_almost_eq(logic.focus_target, target_before, 0.0001)


func test_oil_requires_10x() -> void:
	var rng := _rng(3)
	var logic := ScopeLogic.new()
	logic.reset(rng, "wright")

	assert_eq(logic.select_objective(40, rng), "")
	assert_eq(logic.objective, 40)
	assert_eq(logic.add_oil(), "Return to 10× before adding oil.")
	assert_false(logic.oil)

	assert_eq(logic.select_objective(10, rng), "")
	assert_eq(logic.objective, 10)
	assert_eq(logic.add_oil(), "")
	assert_true(logic.oil)
	assert_eq(logic.add_oil(), "Oil is already on the slide.")


func test_unknown_objective_is_rejected() -> void:
	var rng := _rng(4)
	var logic := ScopeLogic.new()
	logic.reset(rng, "wright")
	assert_eq(logic.select_objective(20, rng), "Unknown objective.")
	assert_eq(logic.select_objective(0, rng), "Unknown objective.")
	assert_eq(logic.objective, 10)


func test_kb_uses_high_dry_without_oil() -> void:
	var rng := _rng(19)
	var logic := ScopeLogic.new()
	logic.reset(rng, "kb")

	assert_eq(logic.add_oil(), "No immersion oil is used in this acid-elution exercise.")
	assert_eq(logic.select_objective(100, rng), "Use 40× high-dry for this acid-elution identification exercise.")
	assert_eq(logic.objective, 10)

	logic.stage_x = 50.0
	assert_eq(logic.blocking_reason(true), "Use 40× high-dry to identify the fetal cell against pale adult-cell ghosts.")

	assert_eq(logic.select_objective(40, rng), "")
	assert_eq(logic.objective, 40)
	logic.focus = logic.focus_target
	assert_eq(logic.blocking_reason(true), "")
	assert_false(logic.oil)


func test_zones() -> void:
	var logic := ScopeLogic.new()
	logic.stage_x = 39.9
	assert_eq(logic.zone(), ScopeLogic.ZONE_THICK)
	logic.stage_x = 40.0
	assert_eq(logic.zone(), ScopeLogic.ZONE_MONO)
	logic.stage_x = 79.9
	assert_eq(logic.zone(), ScopeLogic.ZONE_MONO)
	logic.stage_x = 80.0
	assert_eq(logic.zone(), ScopeLogic.ZONE_EDGE)


func test_blocking_reason_reports_first_obstacle() -> void:
	var rng := _rng(7)
	var logic := ScopeLogic.new()
	logic.reset(rng, "wright")

	logic.stage_x = 20.0
	assert_eq(logic.blocking_reason(true), "Thick area: overlapping red cells obscure morphology. Move toward the monolayer.")
	assert_eq(logic.blocking_reason(false), "Thick area: overlapping red cells obscure morphology. Move toward the monolayer.")

	logic.stage_x = 90.0
	assert_eq(logic.blocking_reason(true), "Feathered edge: distorted cells can mislead morphology assessment. Move back to the monolayer.")

	logic.stage_x = 50.0
	assert_eq(logic.blocking_reason(true), "Monolayer found. At 10× add oil, then select 100× oil for this identification exercise.")

	assert_eq(logic.add_oil(), "")
	assert_eq(logic.select_objective(100, rng), "")
	assert_eq(logic.objective, 100)

	logic.focus_target = 50.0
	logic.focus = 90.0
	assert_eq(logic.blocking_reason(true), "Turn the fine focus until the cells are sharp.")

	logic.focus = 50.0
	assert_eq(logic.blocking_reason(false), "No target cell in this field. Move the stage a little.")
	assert_eq(logic.blocking_reason(true), "")


func test_focus_and_blur() -> void:
	var logic := ScopeLogic.new()
	logic.objective = 10
	assert_true(logic.in_focus())
	assert_almost_eq(logic.blur(), 0.0, 0.0001)

	logic.objective = 40
	logic.focus_target = 50.0
	logic.focus = 56.0
	assert_true(logic.in_focus())
	assert_almost_eq(logic.blur(), 0.0, 0.0001)

	logic.focus = 57.0
	assert_false(logic.in_focus())
	assert_almost_eq(logic.blur(), 7.0 / 40.0, 0.0001)

	logic.focus = 110.0
	assert_almost_eq(logic.blur(), 1.0, 0.0001)


func _ordinary_fixture() -> Dictionary:
	return {
		"normal_rbc": Content.morph["normal_rbc"],
		"spherocyte": Content.morph["spherocyte"],
		"heinz_body": Content.morph["heinz_body"],
		"retic_nmb": Content.morph["retic_nmb"],
		"kleihauer_betke": Content.morph["kleihauer_betke"],
	}


func test_special_preparations_select_matching_target() -> void:
	var rng := _rng(5)
	assert_eq(ScopeLogic.pick_target(Content.morph, rng, "retic"), "retic_nmb")
	assert_eq(ScopeLogic.pick_target(Content.morph, rng, "heinz"), "heinz_body")
	assert_eq(ScopeLogic.pick_target(Content.morph, rng, "kb"), "kleihauer_betke")


func test_retic_and_heinz_use_100x_oil() -> void:
	for preparation: String in ["retic", "heinz"]:
		var rng := _rng(13)
		var logic := ScopeLogic.new()
		logic.reset(rng, preparation)
		assert_eq(logic.add_oil(), "")
		assert_eq(logic.select_objective(100, rng), "")
		assert_eq(logic.objective, 100)
		logic.stage_x = 50.0
		logic.focus = logic.focus_target
		assert_eq(logic.blocking_reason(true), "", "Prep %s should allow classification at 100x oil" % preparation)


func test_wright_giemsa_never_selects_special_preparation_findings() -> void:
	var fixture := _ordinary_fixture()
	assert_true(fixture.has("normal_rbc"))
	assert_true(fixture.has("spherocyte"))
	assert_eq(str(fixture["heinz_body"]["category"]), "inclusion")
	assert_eq(str(fixture["retic_nmb"]["category"]), "stain")
	assert_eq(str(fixture["kleihauer_betke"]["category"]), "stain")

	var rng := _rng(23)
	var seen := {}
	for _i in range(100):
		var picked: String = ScopeLogic.pick_target(fixture, rng, "wright")
		assert_ne(picked, "heinz_body")
		assert_ne(picked, "retic_nmb")
		assert_ne(picked, "kleihauer_betke")
		assert_ne(picked, "")
		seen[picked] = true
	assert_true(seen.has("normal_rbc"))
	assert_true(seen.has("spherocyte"))


func test_sole_eligible_wright_target_is_normal_rbc() -> void:
	var fixture := {
		"normal_rbc": Content.morph["normal_rbc"],
		"heinz_body": Content.morph["heinz_body"],
		"retic_nmb": Content.morph["retic_nmb"],
		"kleihauer_betke": Content.morph["kleihauer_betke"],
	}
	assert_eq(ScopeLogic.pick_target(fixture, _rng(31), "wright"), "normal_rbc")
	assert_eq(ScopeLogic.pick_target({"normal_rbc": Content.morph["normal_rbc"]}, _rng(32), "wright"), "normal_rbc")


func test_choices_list_name_then_first_three_confusers() -> void:
	var entity: Dictionary = Content.morph["kleihauer_betke"]
	var result: Array[String] = ScopeLogic.choices(Content.morph, "kleihauer_betke")
	assert_eq(result.size(), 4)
	assert_eq(result[0], str(entity["name"]))
	for i in range(3):
		var confuser_id := str(entity["confusers"][i])
		assert_eq(result[i + 1], str(Content.morph[confuser_id]["name"]))


func test_layout_separates_targets_from_background() -> void:
	var rng := _rng(101)
	var target_radius: float = CellArt.cell_radius(Content.morph["kleihauer_betke"]["art"], 1.0)
	var cells := ScopeLogic.layout(target_radius, rng)

	var targets: Array[Vector2] = []
	var kinds := {}
	for cell: Dictionary in cells:
		kinds[str(cell["kind"])] = true
		if str(cell["kind"]) == "target":
			targets.append(cell["pos"])
	assert_eq(targets.size(), 8)
	for k in range(8):
		assert_almost_eq(targets[k].x, 42.5 + 5.0 * k, 0.0001)
		assert_between(targets[k].y, ScopeLogic.VIEW_Y - 0.8, ScopeLogic.VIEW_Y + 0.8)

	var clearance: float = target_radius + 0.5
	var closest_gap := INF
	for cell: Dictionary in cells:
		if str(cell["kind"]) == "target":
			continue
		var pos: Vector2 = cell["pos"]
		for target: Vector2 in targets:
			closest_gap = minf(closest_gap, pos.distance_to(target))
	assert_gte(closest_gap, clearance - 0.001)

	for kind: String in kinds:
		assert_true(["rbc", "plt", "edge", "target"].has(kind), "Unexpected cell kind %s" % kind)
	assert_true(kinds.has("rbc"))
	assert_true(kinds.has("edge"))
	assert_true(kinds.has("plt"))


func test_nearest_target_range_and_visibility() -> void:
	var rng := _rng(202)
	var cells := ScopeLogic.layout(1.0, rng)
	var search: float = ScopeLogic.VIEW_RADIUS[100] * 0.85

	assert_eq(ScopeLogic.nearest_target(cells, Vector2(0.0, ScopeLogic.VIEW_Y), search), -1)
	assert_eq(ScopeLogic.nearest_target(cells, Vector2(120.0, ScopeLogic.VIEW_Y), search), -1)

	var target_index := -1
	var target_pos := Vector2.ZERO
	for i in range(cells.size()):
		if str(cells[i]["kind"]) == "target":
			target_index = i
			target_pos = cells[i]["pos"]
			break
	assert_gt(target_index, -1)

	var off_target := Vector2(target_pos.x + search + 0.25, target_pos.y)
	assert_eq(ScopeLogic.nearest_target(cells, off_target, search), -1)
	assert_eq(ScopeLogic.nearest_target(cells, target_pos, search), target_index)
