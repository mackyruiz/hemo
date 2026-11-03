class_name MicroId
extends RefCounted
## Seeded Gram stain, first-test and identification workups for common bacteria.

const GROUP_LABELS := {
	"gpc_clusters": "Gram-positive cocci in clusters",
	"gpc_chains": "Gram-positive cocci in pairs and chains",
	"gnb": "Gram-negative bacilli",
	"gpb": "Gram-positive bacilli",
}
const GROUP_STAINS := {
	"gpc_clusters": "purple (crystal violet–retaining) cocci in grape-like clusters",
	"gpc_chains": "purple cocci in pairs and short chains",
	"gnb": "pink (safranin-counterstained) rods",
}
const GROUP_EXPLANATIONS := {
	"gpc_clusters": "Purple cocci retained crystal violet, so they are gram-positive; grape-like clusters suggest staphylococci rather than streptococci, which form chains.",
	"gpc_chains": "Purple cocci retained crystal violet, so they are gram-positive; pairs and chains suggest streptococci or enterococci rather than staphylococci, which form clusters.",
	"gnb": "Pink rods lost crystal violet during decolorization and took up safranin, so they are gram-negative bacilli rather than gram-positive organisms.",
}
const FIRST_TEST := {"gpc_clusters": "Catalase", "gpc_chains": "Catalase", "gnb": "Oxidase"}
const FIRST_TEST_EXPLANATIONS := {
	"Catalase": "Catalase separates staphylococci (positive) from streptococci and enterococci (negative).",
	"Oxidase": "Oxidase separates Pseudomonas (positive) from the Enterobacterales (negative).",
}
const TEST_CHOICES := ["Catalase", "Oxidase", "Coagulase", "Optochin"]
const ORGANISMS := [
	{"id": "s_aureus", "name": "Staphylococcus aureus", "group": "gpc_clusters", "specimen": "Wound swab", "tests": [
		["Catalase", "Positive"], ["Coagulase", "Positive"], ["Hemolysis on sheep blood agar", "Beta"], ["Mannitol salt agar", "Fermented (yellow)"]]},
	{"id": "s_epidermidis", "name": "Staphylococcus epidermidis", "group": "gpc_clusters", "specimen": "Blood culture (1 of 2 bottles)", "tests": [
		["Catalase", "Positive"], ["Coagulase", "Negative"], ["Novobiocin", "Susceptible"]]},
	{"id": "s_saprophyticus", "name": "Staphylococcus saprophyticus", "group": "gpc_clusters", "specimen": "Urine (young woman with cystitis)", "tests": [
		["Catalase", "Positive"], ["Coagulase", "Negative"], ["Novobiocin", "Resistant"]]},
	{"id": "s_pyogenes", "name": "Streptococcus pyogenes (group A)", "group": "gpc_chains", "specimen": "Throat swab", "tests": [
		["Catalase", "Negative"], ["Hemolysis", "Beta"], ["Bacitracin", "Susceptible"], ["PYR", "Positive"]]},
	{"id": "s_agalactiae", "name": "Streptococcus agalactiae (group B)", "group": "gpc_chains", "specimen": "Vaginal-rectal prenatal screen", "tests": [
		["Catalase", "Negative"], ["Hemolysis", "Beta"], ["CAMP test", "Positive"], ["Hippurate hydrolysis", "Positive"], ["Bacitracin", "Resistant"]]},
	{"id": "s_pneumoniae", "name": "Streptococcus pneumoniae", "group": "gpc_chains", "specimen": "Sputum", "tests": [
		["Catalase", "Negative"], ["Hemolysis", "Alpha"], ["Optochin", "Susceptible"], ["Bile solubility", "Soluble"]]},
	{"id": "e_faecalis", "name": "Enterococcus faecalis", "group": "gpc_chains", "specimen": "Urine", "tests": [
		["Catalase", "Negative"], ["Hemolysis", "Gamma (none)"], ["Bile esculin", "Positive"], ["Growth in 6.5% NaCl", "Positive"], ["PYR", "Positive"]]},
	{"id": "e_coli", "name": "Escherichia coli", "group": "gnb", "specimen": "Urine", "tests": [
		["Oxidase", "Negative"], ["MacConkey", "Lactose fermenter (pink)"], ["Indole", "Positive"], ["Citrate", "Negative"]]},
	{"id": "k_pneumoniae", "name": "Klebsiella pneumoniae", "group": "gnb", "specimen": "Sputum", "tests": [
		["Oxidase", "Negative"], ["MacConkey", "Lactose fermenter, mucoid"], ["Indole", "Negative"], ["Citrate", "Positive"], ["Motility", "Negative"]]},
	{"id": "p_mirabilis", "name": "Proteus mirabilis", "group": "gnb", "specimen": "Urine", "tests": [
		["Oxidase", "Negative"], ["MacConkey", "Non-lactose fermenter"], ["H2S", "Positive"], ["Urease", "Positive"], ["Blood agar", "Swarming"]]},
	{"id": "salmonella", "name": "Salmonella enterica (non-typhoidal)", "group": "gnb", "specimen": "Stool", "tests": [
		["Oxidase", "Negative"], ["MacConkey", "Non-lactose fermenter"], ["H2S", "Positive"], ["Urease", "Negative"], ["Motility", "Positive"]]},
	{"id": "shigella", "name": "Shigella sonnei", "group": "gnb", "specimen": "Stool", "tests": [
		["Oxidase", "Negative"], ["MacConkey", "Non-lactose fermenter"], ["H2S", "Negative"], ["Urease", "Negative"], ["Motility", "Negative"]]},
	{"id": "p_aeruginosa", "name": "Pseudomonas aeruginosa", "group": "gnb", "specimen": "Burn wound", "tests": [
		["Oxidase", "Positive"], ["MacConkey", "Non-lactose fermenter"], ["Odor", "Grape-like"], ["Pigment", "Blue-green (pyocyanin)"], ["Growth at 42 °C", "Positive"]]},
]
const ORGANISM_IDS := [
	"s_aureus", "s_epidermidis", "s_saprophyticus", "s_pyogenes", "s_agalactiae", "s_pneumoniae",
	"e_faecalis", "e_coli", "k_pneumoniae", "p_mirabilis", "salmonella", "shigella", "p_aeruginosa",
]


static func organism(organism_id: String) -> Dictionary:
	for entry: Dictionary in ORGANISMS:
		if entry["id"] == organism_id:
			return entry
	push_error("Unknown organism: " + organism_id)
	return {}


static func questions(organism_id: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var org: Dictionary = organism(organism_id)
	var group: String = org["group"]
	var stain_choices: Array[String] = [GROUP_LABELS[group]]
	for key: String in GROUP_LABELS:
		if key != group:
			stain_choices.append(GROUP_LABELS[key])
	var first: String = FIRST_TEST[group]
	var test_choices: Array[String] = [first]
	for test: String in TEST_CHOICES:
		if test != first:
			test_choices.append(test)
	var lines: Array[String] = []
	for test: Array in org["tests"]:
		lines.append("%s: %s" % [test[0], test[1]])
	var same: Array[String] = []
	var padding: Array[String] = []
	var pad_group: String = ""
	if group == "gpc_clusters":
		pad_group = "gpc_chains"
	elif group == "gpc_chains":
		pad_group = "gpc_clusters"
	for entry: Dictionary in ORGANISMS:
		if entry["id"] == organism_id:
			continue
		if entry["group"] == group:
			same.append(entry["name"])
		elif entry["group"] == pad_group:
			padding.append(entry["name"])
	_shuffle(same, rng)
	_shuffle(padding, rng)
	var id_choices: Array[String] = [org["name"]]
	for name: String in same + padding:
		if id_choices.size() == 4:
			break
		id_choices.append(name)
	return [
		_question("%s: the Gram stain shows %s. How should the Gram stain be reported?" % [org["specimen"], GROUP_STAINS[group]], stain_choices, GROUP_EXPLANATIONS[group]),
		_question("Which test should be performed first to begin identification?", test_choices, FIRST_TEST_EXPLANATIONS[first]),
		_question("Results:\n" + "\n".join(lines) + "\nIdentify the organism.", id_choices, "%s: %s" % [org["name"], "; ".join(lines)]),
	]


static func _question(stem: String, choices: Array[String], explanation: String) -> Dictionary:
	return {"stem": stem, "choices": choices, "answer": 0, "explanation": explanation, "source": "", "image": null, "topic": "micro"}


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: Variant = items[i]
		items[i] = items[j]
		items[j] = value
