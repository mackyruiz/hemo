extends QuestionSeriesBench
## Hepatitis B serologic panel interpretation.


func start(_task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var steps: Array[Dictionary] = []
	for q: Dictionary in HepBPanels.panels(_rng):
		steps.append({"q": q, "lines": []})
	run("Immunology", "immuno", "immuno:hepatitis_b", steps)
