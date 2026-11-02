class_name HemeCalc
extends RefCounted
## Pure hematology calculations. Counts retain the units supplied by the caller.


static func mcv(hct: float, rbc: float) -> float:
	return hct * 10.0 / rbc


static func mch(hgb: float, rbc: float) -> float:
	return hgb * 10.0 / rbc


static func mchc(hgb: float, hct: float) -> float:
	return hgb * 100.0 / hct


static func absolute(wbc: float, pct: float) -> float:
	return wbc * pct / 100.0


static func corrected_wbc(wbc: float, nrbc_per_100: float) -> float:
	return wbc * 100.0 / (100.0 + nrbc_per_100)


static func corrected_retic(retic_pct: float, hct: float, normal_hct: float = 45.0) -> float:
	return retic_pct * hct / normal_hct


static func maturation_factor(hct: float) -> float:
	if hct >= 40.0:
		return 1.0
	if hct >= 30.0:
		return 1.5
	if hct >= 20.0:
		return 2.0
	return 2.5


static func rpi(retic_pct: float, hct: float) -> float:
	return corrected_retic(retic_pct, hct) / maturation_factor(hct)


static func inr(pt: float, mnpt: float, isi: float) -> float:
	return pow(pt / mnpt, isi)


static func hemocytometer(cells: float, area_mm2: float, dilution: float, depth_mm: float = 0.1) -> float:
	return cells * dilution / (area_mm2 * depth_mm)


static func rule_of_three_ok(hgb: float, hct: float, tol: float = 3.0) -> bool:
	return absf(hgb * 3.0 - hct) <= tol
