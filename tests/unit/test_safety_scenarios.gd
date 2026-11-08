extends GutTest

## The safety bench renders scenario steps straight through QuestionPanel, so a bad
## choice count, an out-of-range answer or a source id that is not in data/sources.json
## would reach the player as a broken step or a dead Read-more link. ContentValidator
## cannot see these, because the scenarios are GDScript rather than JSON content.


func test_every_scenario_is_well_formed() -> void:
	var ids: Dictionary = {}
	for scenario: Dictionary in SafetyScenarios.SCENARIOS:
		var id: String = String(scenario.get("id", ""))
		assert_true(id.begins_with("safety-scn-"), "%s needs a safety-scn- id" % id)
		assert_false(ids.has(id), "duplicate scenario id " + id)
		ids[id] = true
		assert_false(String(scenario.get("title", "")).strip_edges().is_empty(), "%s needs a title" % id)
		assert_false(String(scenario.get("vignette", "")).strip_edges().is_empty(), "%s needs a vignette" % id)
		var difficulty: int = int(scenario.get("difficulty", 0))
		assert_between(difficulty, 1, 3, "%s difficulty must be 1..3" % id)
		var steps: Array = scenario.get("steps", [])
		assert_between(steps.size(), 2, 3, "%s needs two or three steps" % id)


func test_every_step_is_answerable_and_sourced() -> void:
	for scenario: Dictionary in SafetyScenarios.SCENARIOS:
		var id: String = String(scenario["id"])
		for index in (scenario["steps"] as Array).size():
			var step: Dictionary = scenario["steps"][index]
			var where: String = "%s step %d" % [id, index]
			assert_false(String(step.get("stem", "")).strip_edges().is_empty(), where + " needs a stem")
			var choices: Array = step.get("choices", [])
			assert_eq(choices.size(), 4, where + " needs four choices")
			var distinct: Dictionary = {}
			for choice: Variant in choices:
				var text: String = String(choice).strip_edges()
				assert_false(text.is_empty(), where + " has an empty choice")
				assert_false(distinct.has(text.to_lower()), where + " repeats a choice")
				distinct[text.to_lower()] = true
			assert_between(int(step.get("answer", -1)), 0, choices.size() - 1, where + " answer out of range")
			assert_false(String(step.get("explanation", "")).strip_edges().is_empty(), where + " needs an explanation")
			var source: String = String(step.get("source", ""))
			assert_true(Content.sources.has(source), where + " cites unknown source " + source)


func test_each_illustration_belongs_to_exactly_one_scenario() -> void:
	var used: Dictionary = {}
	for scenario: Dictionary in SafetyScenarios.SCENARIOS:
		var art: String = String(scenario.get("art", ""))
		assert_true(ScenarioArt.has_kind(art), "%s needs a drawing (%s)" % [String(scenario["id"]), art])
		assert_false(used.has(art), "the drawing %s would repeat" % art)
		used[art] = true
	for kind: String in ScenarioArt.KINDS:
		assert_true(used.has(kind), "the drawing %s is never shown" % kind)


func test_pick_returns_a_scenario() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 20:
		assert_true(SafetyScenarios.SCENARIOS.has(SafetyScenarios.pick(rng)), "pick must return a listed scenario")
