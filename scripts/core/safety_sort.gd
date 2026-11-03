class_name SafetySort
extends RefCounted
## Lab waste items and their disposal containers for the safety sort bench.

const BINS := ["Sharps container", "Biohazard bag (red bag)", "Hazardous chemical waste", "Regular trash"]
const ITEMS := [
	{"name": "Used needle with tube holder attached", "bin": 0},
	{"name": "Used lancet", "bin": 0},
	{"name": "Glass slide with a blood smear", "bin": 0},
	{"name": "Broken blood-contaminated glass tube", "bin": 0},
	{"name": "Gauze saturated with blood", "bin": 1},
	{"name": "Gloves visibly contaminated with blood", "bin": 1},
	{"name": "Used microbiology culture plates", "bin": 1},
	{"name": "Absorbent pad from a blood spill cleanup", "bin": 1},
	{"name": "Spent xylene from slide staining", "bin": 2},
	{"name": "Expired formalin", "bin": 2},
	{"name": "Waste methanol fixative", "bin": 2},
	{"name": "Broken mercury thermometer", "bin": 2},
	{"name": "Paper towels from handwashing", "bin": 3},
	{"name": "Empty cardboard reagent box", "bin": 3},
	{"name": "Used gloves with no visible blood", "bin": 3},
	{"name": "Plastic packaging from a new supply kit", "bin": 3},
]


## Twelve chips: three items per bin, chosen with rng from that bin's four.
static func pick(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var chips: Array[Dictionary] = []
	for bin_index in range(BINS.size()):
		var pool: Array[Dictionary] = []
		for item: Dictionary in ITEMS:
			if int(item["bin"]) == bin_index:
				pool.append(item)
		pool.remove_at(rng.randi_range(0, pool.size() - 1))
		chips.append_array(pool)
	return chips
