class_name HepBPanels
extends RefCounted
## Hepatitis B serologic panels following the CDC interpretation table.

const MARKERS := ["HBsAg", "Total anti-HBc", "IgM anti-HBc", "Anti-HBs"]
const SCENARIOS := {
	"susceptible": {
		"label": "Susceptible, never infected",
		"values": {"HBsAg": "Negative", "Total anti-HBc": "Negative", "IgM anti-HBc": "Not tested", "Anti-HBs": "Negative"},
		"explanation": "All markers are negative: no current infection, no past infection (anti-HBc negative) and no protective antibody, so the person is susceptible and should be vaccinated.",
	},
	"immune_vaccine": {
		"label": "Immune due to hepatitis B vaccination",
		"values": {"HBsAg": "Negative", "Total anti-HBc": "Negative", "IgM anti-HBc": "Not tested", "Anti-HBs": "Positive"},
		"explanation": "Anti-HBs alone means protective antibody without exposure to the virus; the vaccine contains only HBsAg, so it does not produce anti-HBc.",
	},
	"immune_infection": {
		"label": "Immune due to natural infection",
		"values": {"HBsAg": "Negative", "Total anti-HBc": "Positive", "IgM anti-HBc": "Negative", "Anti-HBs": "Positive"},
		"explanation": "Anti-HBc shows past infection and anti-HBs with negative HBsAg shows the infection has resolved with immunity; vaccination alone would not produce anti-HBc.",
	},
	"acute": {
		"label": "Acutely infected",
		"values": {"HBsAg": "Positive", "Total anti-HBc": "Positive", "IgM anti-HBc": "Positive", "Anti-HBs": "Negative"},
		"explanation": "HBsAg shows current infection and IgM anti-HBc marks a recent (acute) infection; chronic infection would have a negative IgM anti-HBc.",
	},
	"chronic": {
		"label": "Chronically infected",
		"values": {"HBsAg": "Positive", "Total anti-HBc": "Positive", "IgM anti-HBc": "Negative", "Anti-HBs": "Negative"},
		"explanation": "HBsAg with total anti-HBc but no IgM anti-HBc indicates an established infection; persistence of HBsAg beyond 6 months defines chronic infection.",
	},
	"isolated_core": {
		"label": "Isolated anti-HBc: interpretation unclear",
		"values": {"HBsAg": "Negative", "Total anti-HBc": "Positive", "IgM anti-HBc": "Negative", "Anti-HBs": "Negative"},
		"explanation": "Anti-HBc alone may mean resolved infection, a false-positive result, low-level chronic infection or a resolving acute infection, so CDC lists it as unclear.",
	},
}
const SCENARIO_IDS := ["susceptible", "immune_vaccine", "immune_infection", "acute", "chronic", "isolated_core"]


static func panels(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var order: Array[String] = []
	order.assign(SCENARIO_IDS)
	_shuffle(order, rng)
	var result: Array[Dictionary] = []
	for scenario_id: String in order.slice(0, 2):
		result.append(question(scenario_id, rng))
	return result


static func question(scenario_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var scenario: Dictionary = SCENARIOS[scenario_id]
	var lines: Array[String] = []
	for marker: String in MARKERS:
		lines.append("%s: %s" % [marker, scenario["values"][marker]])
	var others: Array[String] = []
	for id: String in SCENARIO_IDS:
		if id != scenario_id:
			others.append(SCENARIOS[id]["label"])
	_shuffle(others, rng)
	var choices: Array[String] = [scenario["label"]]
	choices.append_array(others.slice(0, 3))
	return {
		"stem": "Interpret this hepatitis B serologic panel:\n" + "\n".join(lines),
		"choices": choices, "answer": 0, "explanation": scenario["explanation"],
		"source": "", "image": null, "topic": "immuno",
	}


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: Variant = items[i]
		items[i] = items[j]
		items[j] = value
