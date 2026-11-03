extends QuestionSeriesBench
## Gram stain report, first test and organism identification for one isolate.


func start(task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var steps: Array[Dictionary] = []
	for q: Dictionary in MicroId.questions(String(task["organism"]), _rng):
		steps.append({"q": q, "lines": []})
	run("Microbiology", "micro", "micro:identification", steps)
