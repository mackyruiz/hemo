class_name ScopeLogic
extends RefCounted
## Microscope state machine for the Lab Floor: objective, oil, stage and focus,
## plus seeded smear layout helpers (pure logic, no UI).
##
## One unit is one normal RBC diameter. The slide strip runs along x; zones are
## x in [0, 40) thick, [40, 80) monolayer and [80, 120] feathered edge.

const ZONE_THICK := 0
const ZONE_MONO := 1
const ZONE_EDGE := 2
const STRIP := Vector2(120, 12)
const VIEW_Y := 6.0
const STAGE_MIN := 8.0
const STAGE_MAX := 112.0
const VIEW_RADIUS := {10: 8.0, 40: 4.0, 100: 2.6}
const FOCUS_TOLERANCE := 6.0
## Selector labels for the four preparations that together expose every finding
## without pretending special stains are ordinary Wright–Giemsa slides.
const PREPARATIONS := {
	"wright": "Peripheral blood — Wright–Giemsa",
	"retic": "Reticulocytes — new methylene blue",
	"heinz": "Heinz bodies — supravital stain",
	"kb": "Kleihauer–Betke — acid elution",
}

var objective := 10
var oil := false
var stage_x := 20.0
var focus := 50.0
var focus_target := 50.0
var prep := "wright"


func reset(rng: RandomNumberGenerator, preparation: String = "wright") -> void:
	objective = 10
	oil = false
	stage_x = 20.0
	focus = 50.0
	prep = preparation
	focus_target = rng.randf_range(20.0, 80.0)


func zone() -> int:
	if stage_x < 40.0:
		return ZONE_THICK
	if stage_x < 80.0:
		return ZONE_MONO
	return ZONE_EDGE


func select_objective(o: int, rng: RandomNumberGenerator) -> String:
	if o != 10 and o != 40 and o != 100:
		return "Unknown objective."
	if prep == "kb" and o == 100:
		return "Use 40× high-dry for this acid-elution identification exercise."
	if o == 100 and not oil:
		return "Add a drop of immersion oil before rotating in the 100× oil objective."
	if o == 40 and oil:
		return "Oil is on the slide — don't swing the 40× high-dry objective through it. Use 10× or 100× oil."
	if o == objective:
		return ""
	if o != 10:
		focus_target = clampf(focus + rng.randf_range(-15.0, 15.0), 5.0, 95.0)
	objective = o
	return ""


func add_oil() -> String:
	if oil:
		return "Oil is already on the slide."
	if prep == "kb":
		return "No immersion oil is used in this acid-elution exercise."
	if objective != 10:
		return "Return to 10× before adding oil."
	oil = true
	return ""


func in_focus() -> bool:
	return objective == 10 or absf(focus - focus_target) <= FOCUS_TOLERANCE


func blur() -> float:
	if in_focus():
		return 0.0
	return clampf(absf(focus - focus_target) / 40.0, 0.0, 1.0)


func blocking_reason(target_visible: bool) -> String:
	if zone() == ZONE_THICK:
		return "Thick area: overlapping red cells obscure morphology. Move toward the monolayer."
	if zone() == ZONE_EDGE:
		return "Feathered edge: distorted cells can mislead morphology assessment. Move back to the monolayer."
	if prep == "kb":
		if objective != 40:
			return "Use 40× high-dry to identify the fetal cell against pale adult-cell ghosts."
	elif objective != 100:
		return "Monolayer found. At 10× add oil, then select 100× oil for this identification exercise."
	if not in_focus():
		return "Turn the fine focus until the cells are sharp."
	if not target_visible:
		return "No target cell in this field. Move the stage a little."
	return ""


static func layout(target_radius: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	_grid_zone(cells, 0.0, 40.0, 0.8, 0.25, "rbc", rng, false)
	_grid_zone(cells, 40.0, 80.0, 1.15, 0.1, "rbc", rng, true)
	_grid_zone(cells, 80.0, 120.0, 1.8, 0.4, "edge", rng, false)
	var targets: Array[Vector2] = []
	for k in range(8):
		targets.append(Vector2(42.5 + 5.0 * k, VIEW_Y + rng.randf_range(-0.8, 0.8)))
	var clearance: float = target_radius + 0.5
	var kept: Array[Dictionary] = []
	for entry in cells:
		var pos: Vector2 = entry["pos"]
		var clear := true
		for target in targets:
			if pos.distance_to(target) < clearance:
				clear = false
				break
		if clear:
			kept.append(entry)
	for target in targets:
		kept.append({"pos": target, "kind": "target", "seed": rng.randi()})
	return kept


## Fills `cells` with a jittered grid over y in [0.5, 11.5].
static func _grid_zone(cells: Array[Dictionary], x0: float, x1: float, spacing: float, jitter: float, kind: String, rng: RandomNumberGenerator, platelets: bool) -> void:
	var y: float = 0.5
	while y <= 11.5:
		var x: float = x0
		while x < x1:
			var pos := Vector2(x + rng.randf_range(-jitter, jitter), y + rng.randf_range(-jitter, jitter))
			var point_kind: String = kind
			if platelets and rng.randf() < 0.08:
				point_kind = "plt"
			cells.append({"pos": pos, "kind": point_kind, "seed": rng.randi()})
			x += spacing
		y += spacing


static func nearest_target(cells: Array[Dictionary], center: Vector2, max_dist: float) -> int:
	var best := -1
	var best_dist := max_dist
	for i in range(cells.size()):
		if str(cells[i]["kind"]) != "target":
			continue
		var dist: float = center.distance_to(cells[i]["pos"])
		if dist <= max_dist and (best == -1 or dist < best_dist):
			best_dist = dist
			best = i
	return best


static func pick_target(morph: Dictionary, rng: RandomNumberGenerator, preparation: String = "wright") -> String:
	if preparation == "retic":
		return "retic_nmb"
	if preparation == "heinz":
		return "heinz_body"
	if preparation == "kb":
		return "kleihauer_betke"
	var ids: Array[String] = []
	for id: String in morph:
		var entity: Dictionary = morph[id]
		if str(entity.get("category", "")) == "stain":
			continue
		if id == "heinz_body":
			continue
		ids.append(id)
	ids.sort()
	if ids.is_empty():
		return ""
	return ids[rng.randi_range(0, ids.size() - 1)]


static func choices(morph: Dictionary, id: String) -> Array[String]:
	var entity: Dictionary = morph.get(id, {})
	var result: Array[String] = [str(entity.get("name", id))]
	var confusers: Array = entity.get("confusers", [])
	for i in range(mini(3, confusers.size())):
		var confuser_id := str(confusers[i])
		var confuser: Dictionary = morph.get(confuser_id, {})
		result.append(str(confuser.get("name", confuser_id)))
	return result
