class_name SafetySort
extends RefCounted
## Lab waste items and their disposal containers for the safety sort bench.

const BINS := ["Sharps container", "Biohazard bag (red bag)", "Hazardous chemical waste", "Regular trash"]
## One drawing per container, index-matched to BINS (see scripts/ui/sort_art.gd).
const BIN_ART := ["sharps", "biohazard_bag", "chemical_waste", "trash"]
const ITEMS := [
	{"name": "Used needle with tube holder attached", "bin": 0, "art": "needle"},
	{"name": "Used lancet", "bin": 0, "art": "lancet"},
	{"name": "Glass slide with a blood smear", "bin": 0, "art": "slide"},
	{"name": "Broken blood-contaminated glass tube", "bin": 0, "art": "broken_tube"},
	{"name": "Gauze saturated with blood", "bin": 1, "art": "gauze"},
	{"name": "Gloves visibly contaminated with blood", "bin": 1, "art": "glove_soiled"},
	{"name": "Used microbiology culture plates", "bin": 1, "art": "culture_plate"},
	{"name": "Absorbent pad from a blood spill cleanup", "bin": 1, "art": "absorbent_pad"},
	{"name": "Spent xylene from slide staining", "bin": 2, "art": "solvent_bottle"},
	{"name": "Expired formalin", "bin": 2, "art": "formalin_jar"},
	{"name": "Waste methanol fixative", "bin": 2, "art": "wash_bottle"},
	{"name": "Broken mercury thermometer", "bin": 2, "art": "thermometer"},
	{"name": "Paper towels from handwashing", "bin": 3, "art": "paper_towel"},
	{"name": "Empty cardboard reagent box", "bin": 3, "art": "cardboard_box"},
	{"name": "Used gloves with no visible blood", "bin": 3, "art": "glove_clean"},
	{"name": "Plastic packaging from a new supply kit", "bin": 3, "art": "plastic_wrap"},
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
