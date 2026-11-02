extends GutTest


func test_circle_and_ellipse_preserve_dimensions() -> void:
	var circle: PackedVector2Array = CellShapes.circle(30.0, 48)
	assert_eq(circle.size(), 48)
	for point in circle:
		assert_almost_eq(point.length(), 30.0, 0.001)
	var ellipse: PackedVector2Array = CellShapes.ellipse(30.0, 18.0)
	assert_almost_eq(ellipse[0].x, 30.0, 0.001)
	assert_almost_eq(ellipse[12].y, 18.0, 0.001)
	assert_almost_eq(ellipse[24].x, -30.0, 0.001)
	assert_almost_eq(ellipse[36].y, -18.0, 0.001)


func test_bite_removes_membrane_not_cell_center() -> void:
	var bite: PackedVector2Array = CellShapes.bite(30.0)
	assert_true(Geometry2D.is_point_in_polygon(Vector2.ZERO, bite))
	assert_true(Geometry2D.is_point_in_polygon(Vector2(-27, 0), bite))
	assert_false(Geometry2D.is_point_in_polygon(Vector2(27, 0), bite),
		"The bite must remove the right membrane, unlike a disc")
	assert_false(Geometry2D.is_point_in_polygon(Vector2(0, 32), bite))


func test_sickle_has_concave_inner_border() -> void:
	var sickle: PackedVector2Array = CellShapes.sickle(30.0)
	assert_true(Geometry2D.is_point_in_polygon(Vector2(-27, 0), sickle))
	assert_false(Geometry2D.is_point_in_polygon(Vector2.ZERO, sickle),
		"The inner crescent must not become a filled disc")
	assert_false(Geometry2D.is_point_in_polygon(Vector2(27, 0), sickle))


func test_band_keeps_open_center_and_open_right_end() -> void:
	var band: PackedVector2Array = CellShapes.band(30.0)
	assert_false(Geometry2D.is_point_in_polygon(Vector2.ZERO, band))
	assert_true(Geometry2D.is_point_in_polygon(Vector2(-24, 0), band))
	assert_false(Geometry2D.is_point_in_polygon(Vector2(24, 0), band),
		"A band is C-shaped, not a closed ring")


func test_regular_spikes_have_uniform_height_and_spacing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 421
	var points: PackedVector2Array = CellShapes.spiculated(30.0, 20, 4.0, false, rng)
	assert_eq(points.size(), 80, "Each spur has two bases and two knob-tip vertices")
	for i in range(20):
		assert_almost_eq(points[i * 4].length(), 30.0, 0.001)
		assert_almost_eq(points[i * 4 + 1].length(), 34.0, 0.001)
		assert_almost_eq(points[i * 4 + 2].length(), 34.0, 0.001)
		assert_almost_eq(points[i * 4 + 3].length(), 30.0, 0.001)
		if i > 0:
			var delta: float = points[i * 4 + 1].angle() - points[(i - 1) * 4 + 1].angle()
			assert_almost_eq(fposmod(delta, TAU), TAU / 20.0, 0.001)


func test_seeded_irregular_shapes_are_reproducible() -> void:
	var first := RandomNumberGenerator.new()
	var second := RandomNumberGenerator.new()
	first.seed = 88
	second.seed = 88
	assert_eq(CellShapes.fragment(30.0, first), CellShapes.fragment(30.0, second))
	assert_eq(CellShapes.spiculated(30.0, 7, 8.0, true, first), CellShapes.spiculated(30.0, 7, 8.0, true, second))
	assert_eq(CellShapes.lobed_nucleus(30.0, 5, first), CellShapes.lobed_nucleus(30.0, 5, second))
