class_name QcGenerator
extends RefCounted

const SCENARIOS := ["none", "1_2s", "1_3s", "2_2s_within", "2_2s_across", "R_4s", "4_1s", "10_x"]
const ANALYTES := [
	{"analyte": "WBC", "unit": "×10³/µL", "means": [3.0, 15.0], "sds": [0.15, 0.5]},
	{"analyte": "HGB", "unit": "g/dL", "means": [6.0, 16.0], "sds": [0.15, 0.3]},
	{"analyte": "PLT", "unit": "×10³/µL", "means": [70.0, 450.0], "sds": [5.0, 20.0]},
]


static func generate(scenario: String, rng: RandomNumberGenerator) -> Dictionary:
	if scenario not in SCENARIOS:
		push_error("Unknown QC scenario: " + scenario)
		return {}
	var analyte: Dictionary = ANALYTES[rng.randi_range(0, ANALYTES.size() - 1)]
	var expected: String = scenario
	if scenario == "none":
		expected = ""
	elif scenario.begins_with("2_2s_"):
		expected = "2_2s"
	while true:
		var l1: Array[float] = []
		var l2: Array[float] = []
		var clean: bool = true
		for _run in range(19):
			l1.append(clampf(rng.randfn(0.0, 0.8), -1.8, 1.8))
			l2.append(clampf(rng.randfn(0.0, 0.8), -1.8, 1.8))
			if not Westgard.evaluate(l1, l2).is_empty():
				clean = false
				break
		if not clean:
			continue
		l1.append(rng.randf_range(-1.49, 1.49))
		l2.append(rng.randf_range(-1.49, 1.49))
		var sign_value: float = -1.0 if rng.randi_range(0, 1) == 0 else 1.0
		match scenario:
			"1_2s":
				l1[19] = sign_value * rng.randf_range(2.2, 2.8)
			"1_3s":
				l1[19] = sign_value * rng.randf_range(3.2, 3.8)
			"2_2s_within":
				l1[19] = sign_value * rng.randf_range(2.2, 2.8)
				l2[19] = sign_value * rng.randf_range(2.2, 2.8)
			"2_2s_across":
				l1[18] = sign_value * rng.randf_range(2.2, 2.8)
				l1[19] = sign_value * rng.randf_range(2.2, 2.8)
			"R_4s":
				l1[19] = rng.randf_range(2.2, 2.8)
				l2[19] = -rng.randf_range(2.2, 2.8)
			"4_1s":
				for i in range(16, 20):
					l1[i] = sign_value * rng.randf_range(1.2, 1.8)
			"10_x":
				for i in range(10, 20):
					l1[i] = sign_value * rng.randf_range(0.3, 0.9)
		if Westgard.most_severe(Westgard.evaluate(l1, l2)) != expected:
			continue
		var levels: Array[Dictionary] = []
		for index in range(2):
			var z: Array[float] = l1 if index == 0 else l2
			var mean_value: float = analyte["means"][index]
			var sd: float = analyte["sds"][index]
			var values: Array[float] = []
			for point: float in z:
				values.append(roundf((mean_value + point * sd) * 100.0) / 100.0)
			levels.append({"name": "Level %d" % (index + 1), "mean": mean_value, "sd": sd, "z": z, "values": values})
		return {"analyte": analyte["analyte"], "unit": analyte["unit"], "scenario": scenario, "expected_rule": expected, "levels": levels}
	return {}
