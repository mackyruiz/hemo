class_name Topics
extends RefCounted
## Question topic ids, display names, and ASCP exam content areas.

const NAMES := {
	"phys": "Physiology", "rbc": "RBC disorders", "wbc": "WBC disorders",
	"plt": "Platelet disorders", "lab": "Lab testing & morphology",
	"hemo": "Hemostasis", "qc": "QC & lab operations",
	"bb": "Blood banking", "ua": "Urinalysis & body fluids", "chem": "Chemistry",
	"immuno": "Immunology", "micro": "Microbiology", "safety": "Lab safety",
}
const AREAS := {
	"Hematology": ["phys", "rbc", "wbc", "plt", "lab", "hemo"],
	"Blood banking": ["bb"], "Urinalysis & body fluids": ["ua"], "Chemistry": ["chem"],
	"Immunology": ["immuno"], "Microbiology": ["micro"], "Lab operations": ["qc", "safety"],
}


static func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in NAMES:
		out.append(id)
	return out
