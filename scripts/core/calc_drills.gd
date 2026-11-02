class_name CalcDrills
extends RefCounted

const TYPES := ["mcv", "mch", "mchc", "absolute", "corrected_wbc", "corrected_retic", "rpi", "hemocytometer", "inr"]


static func generate(type: String, rng: RandomNumberGenerator) -> Dictionary:
	var inputs: Dictionary = {}
	var answer: float = 0.0
	var decimals: int = 1
	var topic: String = "lab"
	var stem: String = ""
	var explanation: String = ""
	var unit: String = ""
	match type:
		"mcv":
			var hct: float = round_to(rng.randf_range(25.0, 50.0), 1)
			var rbc: float = round_to(rng.randf_range(2.5, 6.0), 2)
			inputs = {"hct": hct, "rbc": rbc}
			answer = HemeCalc.mcv(hct, rbc)
			decimals = 0
			unit = "fL"
			stem = "Hct is %.1f%% and RBC count is %.2f ×10⁶/µL. Calculate MCV." % [hct, rbc]
			explanation = "MCV = Hct × 10 / RBC = %.1f × 10 / %.2f." % [hct, rbc]
		"mch":
			var hgb: float = round_to(rng.randf_range(7.0, 17.0), 1)
			var rbc: float = round_to(rng.randf_range(2.5, 6.0), 2)
			inputs = {"hgb": hgb, "rbc": rbc}
			answer = HemeCalc.mch(hgb, rbc)
			unit = "pg"
			stem = "Hgb is %.1f g/dL and RBC count is %.2f ×10⁶/µL. Calculate MCH." % [hgb, rbc]
			explanation = "MCH = Hgb × 10 / RBC = %.1f × 10 / %.2f." % [hgb, rbc]
		"mchc":
			var hgb: float = round_to(rng.randf_range(7.0, 17.0), 1)
			var hct: float = round_to(hgb * rng.randf_range(2.7, 3.3), 1)
			inputs = {"hgb": hgb, "hct": hct}
			answer = HemeCalc.mchc(hgb, hct)
			unit = "g/dL"
			stem = "Hgb is %.1f g/dL and Hct is %.1f%%. Calculate MCHC." % [hgb, hct]
			explanation = "MCHC = Hgb × 100 / Hct = %.1f × 100 / %.1f." % [hgb, hct]
		"absolute":
			var wbc: float = round_to(rng.randf_range(2.0, 30.0), 1)
			var pct: int = rng.randi_range(1, 90)
			inputs = {"wbc": wbc, "pct": pct}
			answer = HemeCalc.absolute(wbc, pct)
			unit = "×10³/µL"
			stem = "WBC count is %.1f ×10³/µL and lymphocytes are %d%%. Calculate the absolute lymphocyte count." % [wbc, pct]
			explanation = "Absolute count = WBC × percentage / 100 = %.1f × %d / 100." % [wbc, pct]
		"corrected_wbc":
			var wbc: float = round_to(rng.randf_range(5.0, 40.0), 1)
			var nrbc: int = rng.randi_range(5, 50)
			inputs = {"wbc": wbc, "nrbc_per_100": nrbc}
			answer = HemeCalc.corrected_wbc(wbc, nrbc)
			unit = "×10³/µL"
			stem = "An uncorrected WBC count is %.1f ×10³/µL, with %d nRBCs per 100 WBCs. Calculate corrected WBC." % [wbc, nrbc]
			explanation = "Corrected WBC = WBC × 100 / (100 + nRBCs per 100 WBCs) = %.1f × 100 / (100 + %d)." % [wbc, nrbc]
		"corrected_retic", "rpi":
			var retic: float = round_to(rng.randf_range(0.5, 15.0), 1)
			var hct: float = round_to(rng.randf_range(15.0, 45.0), 1)
			inputs = {"retic_pct": retic, "hct": hct, "normal_hct": 45.0}
			answer = HemeCalc.corrected_retic(retic, hct)
			unit = "%"
			stem = "Reticulocytes are %.1f%% and Hct is %.1f%%. Use a normal Hct of 45%%. Calculate corrected reticulocyte percentage." % [retic, hct]
			explanation = "Corrected reticulocytes = reticulocytes × Hct / normal Hct = %.1f × %.1f / 45." % [retic, hct]
			if type == "rpi":
				var factor: float = HemeCalc.maturation_factor(hct)
				inputs["maturation_factor"] = factor
				answer = HemeCalc.rpi(retic, hct)
				unit = "index"
				stem = "Reticulocytes are %.1f%% and Hct is %.1f%%. Use normal Hct 45%% and maturation factors: Hct ≥40%%: 1; 30–39.9%%: 1.5; 20–29.9%%: 2; <20%%: 2.5. Calculate RPI." % [retic, hct]
				explanation = "RPI = (reticulocytes × Hct / 45) / maturation factor = (%.1f × %.1f / 45) / %.1f." % [retic, hct, factor]
		"hemocytometer":
			var cells: int = rng.randi_range(50, 400)
			var area: float = 4.0 if rng.randi_range(0, 1) == 0 else 9.0
			var dilution: float = 20.0 if rng.randi_range(0, 1) == 0 else 100.0
			inputs = {"cells": cells, "area_mm2": area, "dilution": dilution, "depth_mm": 0.1}
			answer = HemeCalc.hemocytometer(cells, area, dilution)
			decimals = 0
			unit = "cells/µL"
			stem = "Counted %d cells in %.0f mm² at dilution factor %.0f (1:%.0f), chamber depth 0.1 mm. Calculate cells/µL." % [cells, area, dilution, dilution]
			explanation = "Cells/µL = cells × dilution / (area × depth) = %d × %.0f / (%.0f × 0.1)." % [cells, dilution, area]
		"inr":
			var pt: float = round_to(rng.randf_range(10.0, 60.0), 1)
			var mnpt: float = round_to(rng.randf_range(11.0, 13.0), 1)
			var isi: float = round_to(rng.randf_range(0.9, 1.5), 2)
			inputs = {"pt": pt, "mnpt": mnpt, "isi": isi}
			answer = HemeCalc.inr(pt, mnpt, isi)
			topic = "hemo"
			unit = "INR"
			stem = "Patient PT is %.1f s, mean normal PT (MNPT) is %.1f s and ISI is %.2f. Calculate INR." % [pt, mnpt, isi]
			explanation = "INR = (patient PT / MNPT)^ISI = (%.1f / %.1f)^%.2f." % [pt, mnpt, isi]
		_:
			push_error("Unknown calculation drill: " + type)
			return {}
	stem += " Round to %d decimal place%s." % [decimals, "" if decimals == 1 else "s"]
	explanation += " Result: %s %s." % [String.num(answer, decimals), unit]
	return {"type": type, "topic": topic, "stem": stem, "answer": answer, "decimals": decimals, "unit": unit, "explanation": explanation, "inputs": inputs}


static func round_to(value: float, decimals: int) -> float:
	var factor: float = pow(10.0, decimals)
	return roundf(value * factor) / factor


static func is_correct(drill: Dictionary, input: float) -> bool:
	var decimals: int = int(drill["decimals"])
	return absf(input - round_to(float(drill["answer"]), decimals)) <= pow(10.0, -decimals) + 1e-9
