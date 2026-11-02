class_name Leitner
extends RefCounted

const INTERVAL_DAYS := [0, 1, 3, 7, 14]


static func update(entry: Dictionary, correct: bool, now: int) -> Dictionary:
	var box: int = int(entry.get("box", 1))
	box = mini(box + 1, 5) if correct else 1
	return {
		"box": box,
		"due": now + int(INTERVAL_DAYS[box - 1]) * 86400,
		"attempts": int(entry.get("attempts", 0)) + 1,
		"correct": int(entry.get("correct", 0)) + (1 if correct else 0),
	}


static func is_due(entry: Dictionary, now: int) -> bool:
	return int(entry.get("due", 0)) <= now
