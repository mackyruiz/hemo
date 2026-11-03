class_name ChemCalcs
extends RefCounted
## Seeded clinical chemistry calculation drills in the CalcDrills shape.

const TYPES := ["anion_gap", "osmolality", "ldl_friedewald", "non_hdl", "ag_ratio", "creatinine_clearance", "transferrin_saturation", "indirect_bilirubin"]


static func anion_gap(na: float, cl: float, hco3: float) -> float:
	return na - (cl + hco3)


static func osmolality(na: float, glucose: float, bun: float) -> float:
	return 2.0 * na + glucose / 18.0 + bun / 2.8


static func ldl_friedewald(tc: float, hdl: float, tg: float) -> float:
	return tc - hdl - tg / 5.0


static func non_hdl(tc: float, hdl: float) -> float:
	return tc - hdl


static func ag_ratio(tp: float, alb: float) -> float:
	return alb / (tp - alb)


static func creatinine_clearance(u: float, p: float, v_ml_24h: float) -> float:
	return u * v_ml_24h / (p * 1440.0)


static func transferrin_saturation(iron: float, tibc: float) -> float:
	return iron / tibc * 100.0


static func indirect_bilirubin(total: float, direct: float) -> float:
	return total - direct


static func generate(type: String, rng: RandomNumberGenerator) -> Dictionary:
	var inputs: Dictionary = {}
	var answer: float = 0.0
	var decimals: int = 0
	var unit: String = ""
	var stem: String = ""
	var explanation: String = ""
	match type:
		"anion_gap":
			var na: int = rng.randi_range(130, 150)
			var cl: int = rng.randi_range(95, 110)
			# Keep the gap positive: HCO3 never exceeds Na - Cl - 3.
			var hco3: int = rng.randi_range(15, mini(30, na - cl - 3))
			inputs = {"na": na, "cl": cl, "hco3": hco3}
			answer = anion_gap(na, cl, hco3)
			unit = "mmol/L"
			stem = "Sodium is %d mmol/L, chloride is %d mmol/L and bicarbonate is %d mmol/L. Calculate the anion gap." % [na, cl, hco3]
			explanation = "Anion gap = Na − (Cl + HCO3) = %d − (%d + %d)." % [na, cl, hco3]
		"osmolality":
			var na: int = rng.randi_range(130, 150)
			var glucose: int = rng.randi_range(70, 600)
			var bun: int = rng.randi_range(5, 80)
			inputs = {"na": na, "glucose": glucose, "bun": bun}
			answer = osmolality(na, glucose, bun)
			unit = "mOsm/kg"
			stem = "Sodium is %d mmol/L, glucose is %d mg/dL and BUN is %d mg/dL. Calculate the serum osmolality." % [na, glucose, bun]
			explanation = "Calculated osmolality = 2 × Na + glucose / 18 + BUN / 2.8 = 2 × %d + %d / 18 + %d / 2.8." % [na, glucose, bun]
		"ldl_friedewald":
			var hdl: int = rng.randi_range(30, 80)
			var tg: int = rng.randi_range(50, 399)
			# Keep LDL at least 30 mg/dL so the drill stays clinically plausible.
			var tc: int = rng.randi_range(maxi(150, hdl + ceili(tg / 5.0) + 30), 300)
			inputs = {"tc": tc, "hdl": hdl, "tg": tg}
			answer = ldl_friedewald(tc, hdl, tg)
			unit = "mg/dL"
			stem = "Total cholesterol is %d mg/dL, HDL cholesterol is %d mg/dL and triglycerides are %d mg/dL. Calculate LDL cholesterol with the Friedewald equation." % [tc, hdl, tg]
			explanation = "LDL = total cholesterol − HDL − triglycerides / 5 = %d − %d − %d / 5." % [tc, hdl, tg]
		"non_hdl":
			var tc: int = rng.randi_range(150, 300)
			var hdl: int = rng.randi_range(30, 80)
			inputs = {"tc": tc, "hdl": hdl}
			answer = non_hdl(tc, hdl)
			unit = "mg/dL"
			stem = "Total cholesterol is %d mg/dL and HDL cholesterol is %d mg/dL. Calculate non-HDL cholesterol." % [tc, hdl]
			explanation = "Non-HDL cholesterol = total cholesterol − HDL = %d − %d." % [tc, hdl]
		"ag_ratio":
			var tp: float = _tenths(rng, 5.5, 8.5)
			var alb: float = _tenths(rng, 2.5, minf(5.0, tp - 1.5))
			inputs = {"tp": tp, "alb": alb}
			answer = ag_ratio(tp, alb)
			decimals = 1
			unit = "ratio"
			stem = "Total protein is %.1f g/dL and albumin is %.1f g/dL. Calculate the albumin/globulin (A/G) ratio." % [tp, alb]
			explanation = "Globulin = total protein − albumin = %.1f − %.1f; A/G ratio = albumin / globulin = %.1f / %.1f." % [tp, alb, alb, tp - alb]
		"creatinine_clearance":
			var u: int = rng.randi_range(40, 200)
			var p: float = _tenths(rng, 0.6, 3.0)
			var v: int = rng.randi_range(800, 2500)
			inputs = {"urine_creatinine": u, "plasma_creatinine": p, "volume_ml_24h": v}
			answer = creatinine_clearance(u, p, v)
			unit = "mL/min"
			stem = "Urine creatinine is %d mg/dL, plasma creatinine is %.1f mg/dL and the 24-hour urine volume is %d mL. Calculate creatinine clearance, not corrected for body surface area." % [u, p, v]
			explanation = "Clearance = U × V / P, with V in mL/min = %d × (%d / 1440) / %.1f." % [u, v, p]
		"transferrin_saturation":
			var iron: int = rng.randi_range(20, 200)
			var tibc: int = rng.randi_range(250, 450)
			inputs = {"iron": iron, "tibc": tibc}
			answer = transferrin_saturation(iron, tibc)
			unit = "%"
			stem = "Serum iron is %d µg/dL and TIBC is %d µg/dL. Calculate transferrin saturation." % [iron, tibc]
			explanation = "Transferrin saturation = iron / TIBC × 100 = %d / %d × 100." % [iron, tibc]
		"indirect_bilirubin":
			var total: float = _tenths(rng, 0.5, 15.0)
			var direct: float = _tenths(rng, 0.1, total - 0.1)
			inputs = {"total": total, "direct": direct}
			answer = indirect_bilirubin(total, direct)
			decimals = 1
			unit = "mg/dL"
			stem = "Total bilirubin is %.1f mg/dL and direct (conjugated) bilirubin is %.1f mg/dL. Calculate indirect (unconjugated) bilirubin." % [total, direct]
			explanation = "Indirect bilirubin = total − direct = %.1f − %.1f." % [total, direct]
		_:
			push_error("Unknown chemistry drill: " + type)
			return {}
	stem += " Round to %d decimal place%s." % [decimals, "" if decimals == 1 else "s"]
	explanation += " Result: %s %s." % [String.num(answer, decimals), unit]
	return {"type": type, "topic": "chem", "stem": stem, "answer": answer, "decimals": decimals, "unit": unit, "explanation": explanation, "inputs": inputs}


## Random value on a 0.1 grid between low and high inclusive.
static func _tenths(rng: RandomNumberGenerator, low: float, high: float) -> float:
	return rng.randi_range(roundi(low * 10.0), roundi(high * 10.0)) / 10.0
