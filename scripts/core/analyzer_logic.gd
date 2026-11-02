class_name AnalyzerLogic
extends RefCounted
## Pure analyzer-station helpers: a normal adult CBC and the post-run review action.
##
## Acceptance control rules are NOT reimplemented here; the station reuses
## QcGenerator/Westgard for two-level QC. This module only produces plausible normal
## CBCs inside the adult reference ranges and grades the review decision.

const CBC_KEYS := ["WBC", "RBC", "HGB", "HCT", "MCV", "MCH", "MCHC", "RDW", "PLT", "RETIC"]


static func normal_cbc(sex: String, rng: RandomNumberGenerator) -> Dictionary:
	var rbc: float = snappedf(rng.randf_range(4.8, 5.5) if sex == "M" else rng.randf_range(4.3, 4.8), 0.01)
	var mcv: int = rng.randi_range(86, 92)
	var mchc_target: float = rng.randf_range(33.0, 34.5)
	var hct: float = snappedf(rbc * mcv / 10.0, 0.1)
	var hgb: float = snappedf(hct * mchc_target / 100.0, 0.1)
	var mch: float = snappedf(hgb / rbc * 10.0, 0.1)
	var mchc: float = snappedf(hgb / hct * 100.0, 0.1)
	return {
		"WBC": snappedf(rng.randf_range(5.0, 10.0), 0.1),
		"RBC": rbc,
		"HGB": hgb,
		"HCT": hct,
		"MCV": mcv,
		"MCH": mch,
		"MCHC": mchc,
		"RDW": snappedf(rng.randf_range(12.0, 14.0), 0.1),
		"PLT": rng.randi_range(180, 400),
		"RETIC": snappedf(rng.randf_range(0.8, 2.0), 0.1),
	}


static func review_action(spurious: bool, smear_requested: bool) -> String:
	if spurious:
		return "investigate"
	if smear_requested:
		return "smear"
	return "release"
