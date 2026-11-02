class_name Microhct
extends RefCounted
## Pure microhematocrit logic for the centrifuge station.
##
## The station packs cells in a capillary, reads the RBC column height, grades the
## plasma appearance, and checks rotor balance. All geometry is in millimetres of a
## COLUMN_MM capillary.

const SLOTS := 12
const COLUMN_MM := 50.0
const TOLERANCE := 2.0

const PLASMA := {"normal": "#F2D16B", "icteric": "#C98A12", "lipemic": "#F3EEDD", "hemolyzed": "#D9576B"}

const PLASMA_TEXT := {
	"normal": "Clear, straw-colored plasma is normal.",
	"icteric": "Dark yellow plasma indicates increased bilirubin (icterus).",
	"lipemic": "Milky, turbid plasma indicates lipemia; it can falsely raise hemoglobin, MCH, and MCHC on analyzers.",
	"hemolyzed": "Pink-to-red plasma indicates free hemoglobin from in vivo or collection-related hemolysis.",
}

const PLASMA_LABELS := {
	"normal": "Normal (straw-colored)",
	"icteric": "Icteric (dark yellow)",
	"lipemic": "Lipemic (milky)",
	"hemolyzed": "Hemolyzed (pink-red)",
}


static func generate(rng: RandomNumberGenerator) -> Dictionary:
	var hct: int = rng.randi_range(20, 55)
	var r: float = rng.randf()
	var plasma: String = "normal"
	if r < 0.55:
		plasma = "normal"
	elif r < 0.70:
		plasma = "icteric"
	elif r < 0.85:
		plasma = "lipemic"
	else:
		plasma = "hemolyzed"
	return {"hct": hct, "plasma": plasma}


static func rbc_mm(hct: int) -> float:
	return COLUMN_MM * hct / 100.0


static func read_ok(value: float, hct: int) -> bool:
	return absf(value - hct) <= TOLERANCE


static func is_balanced(slots: Array[int]) -> bool:
	if slots.size() < 2:
		return false
	var seen := {}
	var total := Vector2.ZERO
	for slot: int in slots:
		if slot < 0 or slot >= SLOTS:
			return false
		if seen.has(slot):
			return false
		seen[slot] = true
		total += Vector2.from_angle(TAU * slot / SLOTS)
	return total.length() < 0.01
