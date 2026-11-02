class_name DiffGenerator
extends RefCounted
## Generates a 100-cell manual differential (plus nRBCs) from a profile.

const CLASSES: Array[String] = ["seg", "band", "lymph", "var_lymph", "mono", "eos", "baso", "meta", "myelo", "promyelo", "blast"]
const CLASS_MORPH := {
	"seg": "neutrophil_seg", "band": "neutrophil_band", "lymph": "lymphocyte",
	"var_lymph": "reactive_lymph", "mono": "monocyte", "eos": "eosinophil", "baso": "basophil",
	"meta": "metamyelocyte", "myelo": "myelocyte", "promyelo": "promyelocyte", "blast": "myeloblast",
	"nrbc": "nrbc",
}
const TIER_CLASSES := {
	1: ["seg", "band", "lymph", "mono", "eos", "baso"],
	2: ["seg", "band", "lymph", "mono", "eos", "baso", "var_lymph", "meta", "myelo"],
	3: ["seg", "band", "lymph", "var_lymph", "mono", "eos", "baso", "meta", "myelo", "promyelo", "blast"],
}


## Returns {profile_id, counts: Dictionary, nrbc: int, wbc: float, sequence: Array[String]}.
static func generate(profile: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pct: Dictionary = profile["pct"]
	var counts: Dictionary = {}
	for cls: String in CLASSES:
		if not pct.has(cls):
			continue
		var base: int = int(pct[cls])
		if base <= 0:
			continue
		counts[cls] = maxi(0, base + rng.randi_range(-2, 2))

	var total: int = 0
	for cls: String in counts:
		total += int(counts[cls])
	# Fix the total to 100 by adjusting the largest class.
	var largest: String = ""
	for cls: String in CLASSES:
		if counts.has(cls) and (largest == "" or int(counts[cls]) > int(counts[largest])):
			largest = cls
	if largest != "":
		counts[largest] = int(counts[largest]) + (100 - total)
	# Drop classes that jittered to zero so only meaningful classes remain.
	for cls: String in CLASSES:
		if counts.has(cls) and int(counts[cls]) <= 0:
			counts.erase(cls)

	var cells: Array[String] = []
	for cls: String in CLASSES:
		if counts.has(cls):
			for i in int(counts[cls]):
				cells.append(cls)
	_shuffle(cells, rng)

	var nrbc_range: Array = profile["nrbc"]
	var nrbc: int = rng.randi_range(int(nrbc_range[0]), int(nrbc_range[1]))

	# Interleave nRBCs at random positions in the sequence.
	var sequence: Array[String] = cells.duplicate()
	for i in nrbc:
		sequence.insert(rng.randi_range(0, sequence.size()), "nrbc")

	var wbc_range: Array = profile["wbc"]
	var wbc: float = snappedf(rng.randf_range(float(wbc_range[0]), float(wbc_range[1])), 0.1)

	return {
		"profile_id": profile["id"],
		"counts": counts,
		"nrbc": nrbc,
		"wbc": wbc,
		"sequence": sequence,
	}


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t
