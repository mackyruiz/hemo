class_name LabMap
extends RefCounted
## Tile-grid collision and station lookup for the Lab Floor (pure logic, no UI).
##
## Units are tiles as floats; cell `(x, y)` spans `[x, x+1)`. Every character
## other than `.` is solid: walls, counters and devices.

const LAYOUT: Array[String] = [
	"WWWWWWWWWWW",
	"WaMsbCrbEaW",
	"W.........W",
	"W.........W",
	"W..aaAaa..W",
	"W.........W",
	"W.........W",
	"W.........W",
	"W.........W",
	"WbTb...aLaW",
	"W.........W",
	"Wp.......pW",
	"WWWWWDWWWWW",
]
const STATIONS := {
	"M": "microscope",
	"C": "centrifuge",
	"E": "esr",
	"A": "analyzer",
	"T": "receiving",
	"L": "lis",
	"D": "exit",
}
const DEVICE_SPRITE := {
	"M": "microscope",
	"C": "centrifuge",
	"E": "esr_rack",
	"A": "analyzer",
	"T": "tube_rack",
	"L": "terminal",
}
const STATION_NAMES := {
	"microscope": "Microscope",
	"centrifuge": "Microhematocrit centrifuge",
	"esr": "ESR rack (Westergren)",
	"analyzer": "Hematology analyzer",
	"receiving": "Specimen receiving",
	"lis": "LIS terminal (practice benches)",
	"exit": "Exit to hub",
}
const SPAWN := Vector2(5.5, 10.5)
## Feet box half-extents; the player is wider than deep.
const PLAYER_HALF := Vector2(0.3, 0.2)
const REACH := 0.6
## Movement is split into substeps no longer than this many tiles, so a slow
## frame can never tunnel through a wall.
const MAX_SUBSTEP := 0.2
const BISECT_STEPS := 12


static func grid_size() -> Vector2i:
	return Vector2i(LAYOUT[0].length(), LAYOUT.size())


static func cell(x: int, y: int) -> String:
	if x < 0 or y < 0 or y >= LAYOUT.size() or x >= LAYOUT[0].length():
		return "W"
	return LAYOUT[y][x]


static func is_solid(x: int, y: int) -> bool:
	return cell(x, y) != "."


static func blocked(center: Vector2, half: Vector2) -> bool:
	var mn: Vector2 = center - half
	var mx: Vector2 = center + half
	var x0: int = int(floorf(mn.x))
	var x1: int = int(floorf(mx.x - 0.0001))
	var y0: int = int(floorf(mn.y))
	var y1: int = int(floorf(mx.y - 0.0001))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if is_solid(x, y):
				return true
	return false


static func move(pos: Vector2, motion: Vector2, half: Vector2 = PLAYER_HALF) -> Vector2:
	var steps: int = maxi(1, ceili(maxf(absf(motion.x), absf(motion.y)) / MAX_SUBSTEP))
	var step: Vector2 = motion / float(steps)
	var result: Vector2 = pos
	for _i in range(steps):
		var candidate: Vector2 = result + Vector2(step.x, 0.0)
		if blocked(candidate, half):
			result.x = _bisect_axis(result, candidate.x, true, half)
		else:
			result = candidate
		candidate = result + Vector2(0.0, step.y)
		if blocked(candidate, half):
			result.y = _bisect_axis(result, candidate.y, false, half)
		else:
			result = candidate
	return result


## Bisects between a known-clear position and a blocked axis coordinate,
## keeping every other axis fixed, and returns the last clear coordinate.
static func _bisect_axis(clear: Vector2, target: float, axis_x: bool, half: Vector2) -> float:
	var lo: float = clear.x if axis_x else clear.y
	var hi: float = target
	for _i in range(BISECT_STEPS):
		var mid: float = (lo + hi) * 0.5
		var probe: Vector2 = Vector2(mid, clear.y) if axis_x else Vector2(clear.x, mid)
		if blocked(probe, half):
			hi = mid
		else:
			lo = mid
	return lo


static func station_cells() -> Dictionary:
	var found := {}
	for y in range(LAYOUT.size()):
		for x in range(LAYOUT[y].length()):
			var code: String = LAYOUT[y][x]
			if STATIONS.has(code):
				found[STATIONS[code]] = Vector2i(x, y)
	return found


static func nearest_station(pos: Vector2, reach: float = REACH) -> String:
	var best := ""
	var best_dist := reach
	var cells: Dictionary = station_cells()
	for station_id: String in cells:
		var index: Vector2i = cells[station_id]
		var rect := Rect2(Vector2(index), Vector2.ONE)
		var closest := Vector2(
			clampf(pos.x, rect.position.x, rect.end.x),
			clampf(pos.y, rect.position.y, rect.end.y)
		)
		var dist: float = pos.distance_to(closest)
		if dist < best_dist:
			best_dist = dist
			best = station_id
	return best
