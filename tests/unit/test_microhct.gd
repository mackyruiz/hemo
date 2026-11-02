extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_constants_are_contract() -> void:
	assert_eq(Microhct.SLOTS, 12)
	assert_eq(Microhct.COLUMN_MM, 50.0)
	assert_eq(Microhct.TOLERANCE, 2.0)
	assert_eq(Microhct.PLASMA.size(), 4)
	assert_eq(String(Microhct.PLASMA["hemolyzed"]), "#D9576B")
	for key: String in Microhct.PLASMA:
		assert_true(Microhct.PLASMA_LABELS.has(key), "PLASMA_LABELS must cover %s" % key)
		assert_true(Microhct.PLASMA_TEXT.has(key), "PLASMA_TEXT must cover %s" % key)


func test_balanced_slot_geometry() -> void:
	var opposite: Array[int] = [0, 6]
	assert_true(Microhct.is_balanced(opposite), "[0,6] is balanced")
	var thirds: Array[int] = [0, 4, 8]
	assert_true(Microhct.is_balanced(thirds), "[0,4,8] is balanced")
	var quarters: Array[int] = [3, 9]
	assert_true(Microhct.is_balanced(quarters), "[3,9] is balanced")
	var unbalanced: Array[int] = [0, 5]
	assert_false(Microhct.is_balanced(unbalanced), "[0,5] is not balanced")
	var single: Array[int] = [0]
	assert_false(Microhct.is_balanced(single), "one slot is not balanced")
	var empty: Array[int] = []
	assert_false(Microhct.is_balanced(empty), "no slots is not balanced")
	var duplicates: Array[int] = [0, 0]
	assert_false(Microhct.is_balanced(duplicates), "duplicate slots are not balanced")
	var low: Array[int] = [-1, 1]
	assert_false(Microhct.is_balanced(low), "negative indices are rejected")
	var high: Array[int] = [0, 12]
	assert_false(Microhct.is_balanced(high), "indices at SLOTS are rejected")


func test_rbc_column_and_read_tolerance() -> void:
	assert_almost_eq(Microhct.rbc_mm(42), 21.0, 0.0001)
	assert_almost_eq(Microhct.rbc_mm(50), 25.0, 0.0001)
	assert_true(Microhct.read_ok(40.0, 42), "40 is within tolerance of 42")
	assert_true(Microhct.read_ok(44.0, 42), "44 is within tolerance of 42")
	assert_false(Microhct.read_ok(39.0, 42), "39 is outside tolerance of 42")
	assert_false(Microhct.read_ok(45.0, 42), "45 is outside tolerance of 42")


func test_generate_distribution_and_bounds() -> void:
	var counts := {"normal": 0, "icteric": 0, "lipemic": 0, "hemolyzed": 0}
	for s in range(1000):
		var sample: Dictionary = Microhct.generate(_rng(s))
		var hct := int(sample["hct"])
		var plasma := String(sample["plasma"])
		assert_true(hct >= 20 and hct <= 55, "hct stays 20..55")
		assert_true(Microhct.PLASMA.has(plasma), "plasma key is listed")
		counts[plasma] += 1
	for key: String in counts:
		assert_true(counts[key] > 0, "plasma %s must appear" % key)
	for key: String in counts:
		if key != "normal":
			assert_true(counts["normal"] > counts[key], "normal plasma is the commonest")
