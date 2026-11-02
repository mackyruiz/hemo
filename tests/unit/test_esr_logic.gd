extends GutTest

const AGES := [20, 61, 85]
const SEXES := ["M", "F"]


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_upper_limit_miller_rule() -> void:
	assert_almost_eq(EsrLogic.upper_limit(60, "M"), 30.0, 0.0001)
	assert_almost_eq(EsrLogic.upper_limit(60, "F"), 35.0, 0.0001)
	assert_almost_eq(EsrLogic.upper_limit(61, "M"), 30.5, 0.0001)
	assert_almost_eq(EsrLogic.upper_limit(20, "M"), 10.0, 0.0001)
	assert_almost_eq(EsrLogic.upper_limit(20, "F"), 15.0, 0.0001)


func test_is_increased_boundary() -> void:
	assert_false(EsrLogic.is_increased(30, 60, "M"), "30 is at the approximation for 60M")
	assert_true(EsrLogic.is_increased(31, 60, "M"), "31 is above the approximation for 60M")
	assert_false(EsrLogic.is_increased(30, 61, "M"), "30 is below the approximation for 61M")
	assert_true(EsrLogic.is_increased(31, 61, "M"), "31 is above the approximation for 61M")
	assert_false(EsrLogic.is_increased(35, 60, "F"), "35 is at the approximation for 60F")
	assert_true(EsrLogic.is_increased(36, 60, "F"), "36 is above the approximation for 60F")


func test_final_value_branches_independently() -> void:
	for age in AGES:
		for sex in SEXES:
			var limit: float = EsrLogic.upper_limit(age, sex)
			var floor: int = int(limit)
			for s in range(300):
				var above: int = EsrLogic.final_value(age, sex, true, _rng(s))
				assert_true(above > limit, "above-branch exceeds the approximation (%d %s)" % [age, sex])
				assert_true(above >= floor + 5, "above-branch adds at least 5")
				assert_true(above <= 150, "above-branch is capped at 150")
				var below: int = EsrLogic.final_value(age, sex, false, _rng(s))
				assert_true(below <= limit, "below-branch never exceeds the approximation (%d %s)" % [age, sex])
				assert_true(below <= floor - 2 or below == 3 or below == 2, "below-branch stays under the approximation")
				assert_true(below >= 2, "below-branch is at least 2")


func test_front_mm_piecewise_and_clamped() -> void:
	assert_almost_eq(EsrLogic.front_mm(0.0, 100), 0.0, 0.0001)
	assert_almost_eq(EsrLogic.front_mm(10.0, 100), 10.0, 0.0001)
	assert_almost_eq(EsrLogic.front_mm(40.0, 100), 85.0, 0.0001)
	assert_almost_eq(EsrLogic.front_mm(60.0, 100), 100.0, 0.0001)
	assert_almost_eq(EsrLogic.front_mm(-5.0, 100), 0.0, 0.0001)
	assert_almost_eq(EsrLogic.front_mm(120.0, 100), 100.0, 0.0001)
	var previous := -1.0
	for m in range(61):
		var value: float = EsrLogic.front_mm(float(m), 100)
		assert_true(value >= previous, "front is monotonic at %d minutes" % m)
		assert_true(value >= 0.0 and value <= 100.0, "front stays within 0..final at %d minutes" % m)
		previous = value


func test_read_tolerance() -> void:
	assert_true(EsrLogic.read_ok(98.0, 100), "98 is within tolerance of 100")
	assert_true(EsrLogic.read_ok(102.0, 100), "102 is within tolerance of 100")
	assert_false(EsrLogic.read_ok(97.0, 100), "97 is outside tolerance of 100")
	assert_false(EsrLogic.read_ok(103.0, 100), "103 is outside tolerance of 100")
	assert_true(EsrLogic.read_ok(30.0, 30), "exact reading is accepted")


func test_generate_ranges_and_variety() -> void:
	var sexes := {}
	var tilted_values := {}
	var increased := {}
	for s in range(600):
		var sample: Dictionary = EsrLogic.generate(_rng(s))
		var age := int(sample["age"])
		var sex := String(sample["sex"])
		var final_mm := int(sample["final_mm"])
		assert_true(age >= 20 and age <= 85, "age stays 20..85")
		assert_true(sex == "M" or sex == "F", "sex is M or F")
		assert_true(final_mm >= 2 and final_mm <= 150, "final_mm stays 2..150")
		assert_true(typeof(sample["tilted"]) == TYPE_BOOL, "tilted is a bool")
		sexes[sex] = true
		tilted_values[sample["tilted"]] = true
		increased[EsrLogic.is_increased(final_mm, age, sex)] = true
	assert_true(sexes.has("M") and sexes.has("F"), "both sexes occur")
	assert_true(tilted_values.has(true) and tilted_values.has(false), "both tilt states occur")
	assert_true(increased.has(true) and increased.has(false), "both approximation branches occur")
