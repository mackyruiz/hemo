class_name EsrLogic
extends RefCounted
## Pure ESR (erythrocyte sedimentation rate) logic for the Westergren station.
##
## Values follow the Miller approximation of the upper limit of normal. The station
## drops a column and lets the player read the 60-minute front from a graph.

const READ_TOLERANCE := 2.0


static func upper_limit(age: int, sex: String) -> float:
	if sex == "M":
		return age / 2.0
	return (age + 10) / 2.0


static func final_value(age: int, sex: String, above_approximation: bool, rng: RandomNumberGenerator) -> int:
	var limit: int = int(upper_limit(age, sex))
	if above_approximation:
		return mini(150, limit + rng.randi_range(5, 60))
	return rng.randi_range(2, maxi(3, limit - 2))


static func generate(rng: RandomNumberGenerator) -> Dictionary:
	var age: int = rng.randi_range(20, 85)
	var sex: String = "M" if rng.randi_range(0, 1) == 0 else "F"
	var above: bool = rng.randf() < 0.5
	var final_mm: int = final_value(age, sex, above, rng)
	var tilted: bool = rng.randf() < 0.35
	return {"age": age, "sex": sex, "final_mm": final_mm, "tilted": tilted}


static func front_mm(minutes: float, final_mm: int) -> float:
	var final := float(final_mm)
	var value: float
	if minutes <= 10.0:
		value = final * 0.1 * minutes / 10.0
	elif minutes <= 40.0:
		value = final * (0.1 + 0.75 * (minutes - 10.0) / 30.0)
	elif minutes <= 60.0:
		value = final * (0.85 + 0.15 * (minutes - 40.0) / 20.0)
	else:
		value = final
	return clampf(value, 0.0, final)


static func read_ok(value: float, final_mm: int) -> bool:
	return absf(value - final_mm) <= READ_TOLERANCE


static func is_increased(final_mm: int, age: int, sex: String) -> bool:
	return final_mm > upper_limit(age, sex)
