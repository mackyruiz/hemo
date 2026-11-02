class_name Westgard
extends RefCounted
## Strict threshold comparisons; only the final run is evaluated.

const RULES := ["1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x"]
const SEVERITY := ["1_3s", "R_4s", "2_2s", "4_1s", "10_x", "1_2s"]


static func evaluate(l1: Array[float], l2: Array[float]) -> Array[String]:
	var rules: Array[String] = []
	if l1.is_empty() or l2.is_empty():
		return rules
	var a: float = l1[-1]
	var b: float = l2[-1]
	if absf(a) > 2.0 or absf(b) > 2.0:
		rules.append("1_2s")
	if absf(a) > 3.0 or absf(b) > 3.0:
		rules.append("1_3s")
	if (a > 2.0 and b > 2.0) or (a < -2.0 and b < -2.0) or _same_side(l1, 2, 2.0) or _same_side(l2, 2, 2.0):
		rules.append("2_2s")
	if (a > 2.0 and b < -2.0) or (b > 2.0 and a < -2.0):
		rules.append("R_4s")
	if _same_side(l1, 4, 1.0) or _same_side(l2, 4, 1.0):
		rules.append("4_1s")
	if _same_side(l1, 10, 0.0) or _same_side(l2, 10, 0.0):
		rules.append("10_x")
	return rules


static func _same_side(series: Array[float], count: int, threshold: float) -> bool:
	if series.size() < count:
		return false
	var above: bool = true
	var below: bool = true
	for i in range(series.size() - count, series.size()):
		above = above and series[i] > threshold
		below = below and series[i] < -threshold
	return above or below


static func is_reject(rules: Array) -> bool:
	for rule: String in rules:
		if rule != "1_2s":
			return true
	return false


static func error_type(rule: String) -> String:
	if rule in ["1_3s", "R_4s"]:
		return "random"
	if rule in ["2_2s", "4_1s", "10_x"]:
		return "systematic"
	return ""


static func most_severe(rules: Array) -> String:
	for rule: String in SEVERITY:
		if rule in rules:
			return rule
	return ""
