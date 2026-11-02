extends GutTest
## LabMap: tile collision, sliding movement and station proximity.


func test_grid_and_cell_lookup() -> void:
	assert_eq(LabMap.grid_size(), Vector2i(11, 13))
	assert_eq(LabMap.cell(0, 0), "W")
	assert_eq(LabMap.cell(5, 10), ".")
	assert_eq(LabMap.cell(-1, 5), "W")
	assert_eq(LabMap.cell(11, 5), "W")
	assert_eq(LabMap.cell(5, 13), "W")
	assert_true(LabMap.is_solid(0, 0))
	assert_true(LabMap.is_solid(2, 1))
	assert_false(LabMap.is_solid(5, 10))


func test_blocked_detects_overlapping_solid_cells() -> void:
	assert_true(LabMap.blocked(Vector2(2.5, 1.5), LabMap.PLAYER_HALF))
	assert_false(LabMap.blocked(Vector2(2.5, 2.5), LabMap.PLAYER_HALF))
	assert_false(LabMap.blocked(LabMap.SPAWN, LabMap.PLAYER_HALF))


func test_short_moves_stop_at_walls() -> void:
	var left: Vector2 = LabMap.move(Vector2(1.5, 2.5), Vector2(-1.0, 0.0))
	assert_almost_eq(left.x, 1.3, 0.01)
	assert_almost_eq(left.y, 2.5, 0.0001)
	assert_false(LabMap.blocked(left, LabMap.PLAYER_HALF))

	var up: Vector2 = LabMap.move(Vector2(2.5, 2.5), Vector2(0.0, -1.0))
	assert_almost_eq(up.y, 2.2, 0.01)
	assert_almost_eq(up.x, 2.5, 0.0001)
	assert_false(LabMap.blocked(up, LabMap.PLAYER_HALF))


func test_large_moves_do_not_tunnel() -> void:
	var island: Vector2 = LabMap.move(Vector2(2.5, 4.5), Vector2(1.75, 0.0))
	assert_almost_eq(island.x, 2.7, 0.01)
	assert_almost_eq(island.y, 4.5, 0.0001)
	assert_false(LabMap.blocked(island, LabMap.PLAYER_HALF))

	var analyzer: Vector2 = LabMap.move(Vector2(5.5, 5.5), Vector2(0.0, -2.0))
	assert_almost_eq(analyzer.y, 5.2, 0.01)
	assert_almost_eq(analyzer.x, 5.5, 0.0001)
	assert_false(LabMap.blocked(analyzer, LabMap.PLAYER_HALF))


func test_diagonal_move_keeps_free_axis() -> void:
	var diagonal: Vector2 = LabMap.move(Vector2(1.5, 6.5), Vector2(-1.0, -1.0))
	assert_almost_eq(diagonal.x, 1.3, 0.01)
	assert_almost_eq(diagonal.y, 5.5, 0.01)
	assert_false(LabMap.blocked(diagonal, LabMap.PLAYER_HALF))

	var straight: Vector2 = LabMap.move(Vector2(1.5, 6.5), Vector2(-1.0, 0.0))
	assert_almost_eq(straight.x, 1.3, 0.01)
	assert_almost_eq(straight.y, 6.5, 0.0001)


func test_nearest_station() -> void:
	assert_eq(LabMap.nearest_station(Vector2(2.5, 2.3)), "microscope")
	assert_eq(LabMap.nearest_station(Vector2(5.5, 6.5)), "")
	assert_eq(LabMap.nearest_station(Vector2(5.5, 11.6)), "exit")


func test_station_cells_match_layout() -> void:
	var cells: Dictionary = LabMap.station_cells()
	assert_eq(cells.size(), 7)
	assert_eq(cells["microscope"], Vector2i(2, 1))
	assert_eq(cells["centrifuge"], Vector2i(5, 1))
	assert_eq(cells["esr"], Vector2i(8, 1))
	assert_eq(cells["analyzer"], Vector2i(5, 4))
	assert_eq(cells["receiving"], Vector2i(2, 9))
	assert_eq(cells["lis"], Vector2i(8, 9))
	assert_eq(cells["exit"], Vector2i(5, 12))


func test_every_station_is_reachable_from_spawn() -> void:
	var size: Vector2i = LabMap.grid_size()
	var start := Vector2i(int(floor(LabMap.SPAWN.x)), int(floor(LabMap.SPAWN.y)))
	assert_false(LabMap.is_solid(start.x, start.y))

	var seen := {}
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = current + step
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
				continue
			if seen.has(next) or LabMap.is_solid(next.x, next.y):
				continue
			seen[next] = true
			queue.append(next)

	var stations: Dictionary = LabMap.station_cells()
	for station_id: String in stations:
		var station_cell: Vector2i = stations[station_id]
		var reachable := false
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if seen.has(station_cell + step):
				reachable = true
		assert_true(reachable, "Station %s needs a walkable cell reachable from spawn" % station_id)
