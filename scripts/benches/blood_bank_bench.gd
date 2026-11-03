extends QuestionSeriesBench
## ABO/Rh interpretation from forward and reverse grouping, then unit selection.


func start(_task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var panel: Dictionary = BloodTyping.generate(_rng)
	var lines: Array[String] = []
	for reagent: String in panel["forward"]:
		lines.append("Forward grouping — %s: %s" % [reagent, panel["forward"][reagent]])
	for cells: String in panel["reverse"]:
		lines.append("Reverse grouping — %s: %s" % [cells, panel["reverse"][cells]])
	var steps: Array[Dictionary] = []
	for q: Dictionary in panel["questions"]:
		steps.append({"q": q, "lines": lines})
	run("Blood bank", "bb", "bb:abo_rh", steps)
