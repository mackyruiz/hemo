extends QuestionSeriesBench
## Dipstick and sediment report interpretation.


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var scenario: String = String(task["scenario"])
	var lines: Array[String] = UaCases.report_lines(scenario)
	var steps: Array[Dictionary] = []
	for q: Dictionary in UaCases.questions(scenario, _rng):
		steps.append({"q": q, "lines": lines})
	run("Urinalysis", "ua", "ua:interpretation", steps)
