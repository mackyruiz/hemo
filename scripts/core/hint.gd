class_name Hint
extends RefCounted
## 50/50 hint: leaves the correct choice plus one randomly kept wrong choice.

const MIN_CHOICES := 3

## Original indices to remove: every choice except the correct one and one
## randomly kept wrong choice. [] when fewer than MIN_CHOICES choices (a 2-choice
## question would be answered outright by a hint).
static func eliminate(choice_count: int, answer: int, rng: RandomNumberGenerator) -> Array[int]:
	var removed: Array[int] = []
	if choice_count < MIN_CHOICES or answer < 0 or answer >= choice_count:
		return removed
	var wrong: Array[int] = []
	for i in range(choice_count):
		if i != answer:
			wrong.append(i)
	var kept: int = rng.randi_range(0, wrong.size() - 1)
	for i in range(wrong.size()):
		if i != kept:
			removed.append(wrong[i])
	return removed
