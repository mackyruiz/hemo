class_name UaCases
extends RefCounted
## Fixed urinalysis reports (strip plus sediment) with interpretation questions.

const STRIP_ORDER := ["Color", "Clarity", "Specific gravity", "pH", "Protein", "Glucose", "Ketones", "Blood", "Bilirubin", "Urobilinogen", "Nitrite", "Leukocyte esterase"]
const STRIP_DEFAULTS := {"Color": "Yellow", "Clarity": "Clear", "Specific gravity": "1.015", "pH": "6.0", "Urobilinogen": "0.2 EU/dL"}
const SCENARIOS := {
	"normal": {
		"label": "Normal urinalysis",
		"strip": {},
		"sediment": ["0–2 RBC/hpf", "0–5 WBC/hpf", "0–2 hyaline casts/lpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "Which cast can be seen in small numbers in normal urine?",
			"choices": ["Hyaline casts", "RBC casts", "WBC casts", "Waxy casts"],
			"explanation": "Hyaline casts form from Tamm-Horsfall (uromodulin) protein alone, so a few appear in normal urine, especially after exercise or dehydration.",
		},
	},
	"cystitis": {
		"label": "Lower urinary tract infection (cystitis)",
		"strip": {"Clarity": "Cloudy", "Specific gravity": "1.020", "pH": "6.5", "Protein": "Trace", "Blood": "Small", "Nitrite": "Positive", "Leukocyte esterase": "Moderate"},
		"sediment": ["25–50 WBC/hpf", "5–10 RBC/hpf", "Many bacteria", "No casts seen", "Few squamous epithelial cells"],
		"key": {
			"stem": "What does a positive nitrite reaction indicate?",
			"choices": ["Bacteria that reduce nitrate to nitrite", "White cells in the urine", "Red cells in the urine", "Yeast in the urine"],
			"explanation": "Many gram-negative uropathogens reduce dietary nitrate to nitrite, so a positive nitrite reaction indicates bacteriuria.",
		},
	},
	"pyelonephritis": {
		"label": "Acute pyelonephritis",
		"strip": {"Clarity": "Cloudy", "Protein": "1+", "Blood": "Small", "Nitrite": "Positive", "Leukocyte esterase": "Large"},
		"sediment": [">50 WBC/hpf", "WBC casts 2–5/lpf", "Many bacteria", "Few squamous epithelial cells"],
		"key": {
			"stem": "Which sediment element localizes this infection to the kidney?",
			"choices": ["WBC casts", "Bacteria", "Squamous epithelial cells", "Amorphous urates"],
			"explanation": "Casts form only in the renal tubules, so WBC casts place the inflammation in the kidney rather than the bladder.",
		},
	},
	"glomerulonephritis": {
		"label": "Acute glomerulonephritis",
		"strip": {"Color": "Red-brown (smoky)", "Clarity": "Hazy", "Specific gravity": "1.020", "Protein": "2+", "Blood": "Large"},
		"sediment": [">50 RBC/hpf, many dysmorphic", "RBC casts 2–5/lpf", "5–10 WBC/hpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "Which finding confirms that the bleeding is glomerular?",
			"choices": ["RBC casts", "Hyaline casts", "Calcium oxalate crystals", "Squamous epithelial cells"],
			"explanation": "RBC casts form when red cells cross a damaged glomerulus and are trapped in tubular casts, so they confirm glomerular bleeding.",
		},
	},
	"nephrotic": {
		"label": "Nephrotic syndrome",
		"strip": {"Clarity": "Clear, foamy", "Specific gravity": "1.025", "Protein": "4+"},
		"sediment": ["Oval fat bodies", "Fatty casts 2–5/lpf", "0–2 RBC/hpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "Oval fat bodies are renal tubular cells filled with what?",
			"choices": ["Absorbed lipid", "Hemoglobin", "Bilirubin", "Glycogen"],
			"explanation": "In nephrotic syndrome, renal tubular epithelial cells absorb filtered lipoproteins and appear as oval fat bodies.",
		},
	},
	"dka": {
		"label": "Diabetic ketoacidosis",
		"strip": {"Color": "Pale yellow", "Specific gravity": "1.030", "pH": "5.0", "Glucose": "4+ (≥1000 mg/dL)", "Ketones": "Large"},
		"sediment": ["0–2 RBC/hpf", "0–5 WBC/hpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "Which ketone does the nitroprusside reagent strip detect?",
			"choices": ["Acetoacetic acid", "β-hydroxybutyrate", "Lactic acid", "Pyruvic acid"],
			"explanation": "Sodium nitroprusside reacts with acetoacetic acid (and acetone with glycine added) but not with β-hydroxybutyrate.",
		},
	},
	"hemoglobinuria": {
		"label": "Hemoglobinuria (intravascular hemolysis)",
		"strip": {"Color": "Red", "Blood": "Large"},
		"sediment": ["0–2 RBC/hpf", "0–5 WBC/hpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "A large blood reaction with no RBCs in the sediment is explained by which substances?",
			"choices": ["Free hemoglobin or myoglobin", "Bilirubin", "Ascorbic acid", "Porphobilinogen"],
			"explanation": "The blood pad detects the peroxidase activity of heme, so free hemoglobin or myoglobin reacts even when intact red cells are absent.",
		},
	},
	"obstructive_jaundice": {
		"label": "Posthepatic (obstructive) jaundice",
		"strip": {"Color": "Dark amber, yellow foam", "Bilirubin": "Moderate", "Urobilinogen": "0.2 EU/dL (not increased)"},
		"sediment": ["0–2 RBC/hpf", "0–5 WBC/hpf", "Few squamous epithelial cells"],
		"key": {
			"stem": "Why is urine urobilinogen not increased in complete bile duct obstruction?",
			"choices": ["Bilirubin cannot reach the intestine to form urobilinogen", "The kidney destroys urobilinogen", "Conjugated bilirubin is not filtered", "The strip cannot detect urobilinogen"],
			"explanation": "Intestinal bacteria make urobilinogen from bilirubin, so a blocked bile duct keeps bilirubin out of the gut and urobilinogen stays low.",
		},
	},
}
const SCENARIO_IDS := ["normal", "cystitis", "pyelonephritis", "glomerulonephritis", "nephrotic", "dka", "hemoglobinuria", "obstructive_jaundice"]


static func strip(scenario_id: String) -> Dictionary:
	var deviations: Dictionary = SCENARIOS[scenario_id]["strip"]
	var result: Dictionary = {}
	for analyte: String in STRIP_ORDER:
		result[analyte] = deviations.get(analyte, STRIP_DEFAULTS.get(analyte, "Negative"))
	return result


static func report_lines(scenario_id: String) -> Array[String]:
	var lines: Array[String] = []
	var values: Dictionary = strip(scenario_id)
	for analyte: String in STRIP_ORDER:
		lines.append("%s: %s" % [analyte, values[analyte]])
	for item: String in SCENARIOS[scenario_id]["sediment"]:
		lines.append("Microscopic: " + item)
	return lines


static func questions(scenario_id: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var scenario: Dictionary = SCENARIOS[scenario_id]
	var others: Array[String] = []
	for id: String in SCENARIO_IDS:
		if id != scenario_id:
			others.append(SCENARIOS[id]["label"])
	for i in range(others.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: String = others[i]
		others[i] = others[j]
		others[j] = value
	var labels: Array[String] = [scenario["label"]]
	labels.append_array(others.slice(0, 3))
	var findings: Array[String] = []
	var deviations: Dictionary = scenario["strip"]
	for analyte: String in STRIP_ORDER:
		if deviations.has(analyte):
			findings.append("%s %s" % [analyte, deviations[analyte]])
	for item: String in scenario["sediment"]:
		findings.append(item)
	var key: Dictionary = scenario["key"]
	var key_choices: Array[String] = []
	key_choices.assign(key["choices"])
	return [
		_question("Interpret this urinalysis.", labels, "%s: %s" % [scenario["label"], "; ".join(findings)]),
		_question(key["stem"], key_choices, key["explanation"]),
	]


static func _question(stem: String, choices: Array[String], explanation: String) -> Dictionary:
	return {"stem": stem, "choices": choices, "answer": 0, "explanation": explanation, "source": "", "image": null, "topic": "ua"}
