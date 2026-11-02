extends GutTest

const CBC_KEYS := ["WBC", "RBC", "HGB", "HCT", "MCV", "MCH", "MCHC", "RDW", "PLT", "RETIC"]
const SEXES := ["M", "F"]
const ROUNDED_KEYS := ["WBC", "HGB", "HCT", "MCH", "MCHC", "RDW", "RETIC"]


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _limits(ranges: Dictionary, key: String, sex: String) -> Array:
	var entry: Dictionary = ranges[key]
	if entry.has(sex):
		return [float(entry[sex]["low"]), float(entry[sex]["high"])]
	return [float(entry["low"]), float(entry["high"])]


func test_normal_cbc_returns_all_keys_inside_adult_ranges() -> void:
	var ranges: Dictionary = ContentLoader.load_all()["ranges"]
	assert_gt(ranges.size(), 0, "reference ranges must load")
	for sex in SEXES:
		for s in range(400):
			var cbc: Dictionary = AnalyzerLogic.normal_cbc(sex, _rng(s))
			assert_eq(cbc.size(), CBC_KEYS.size(), "normal_cbc returns exactly the CBC keys")
			for key: String in CBC_KEYS:
				assert_true(cbc.has(key), "normal_cbc must include %s" % key)
				var limits: Array = _limits(ranges, key, sex)
				var value := float(cbc[key])
				assert_true(value >= limits[0] - 0.001 and value <= limits[1] + 0.001, "%s %s = %s outside [%s, %s]" % [key, sex, value, limits[0], limits[1]])


func test_normal_cbc_arithmetic_within_rounding_tolerance() -> void:
	for sex in SEXES:
		for s in range(400):
			var cbc: Dictionary = AnalyzerLogic.normal_cbc(sex, _rng(s))
			var rbc := float(cbc["RBC"])
			var mcv := float(cbc["MCV"])
			var hct := float(cbc["HCT"])
			var hgb := float(cbc["HGB"])
			var mch := float(cbc["MCH"])
			var mchc := float(cbc["MCHC"])
			assert_almost_eq(hct, rbc * mcv / 10.0, 0.06, "HCT = RBC*MCV/10")
			assert_almost_eq(mch, hgb / rbc * 10.0, 0.06, "MCH = HGB/RBC*10")
			assert_almost_eq(mchc, hgb / hct * 100.0, 0.06, "MCHC = HGB/HCT*100")
			for key: String in ROUNDED_KEYS:
				var value := float(cbc[key])
				assert_almost_eq(value, snappedf(value, 0.1), 0.0001, "%s is displayed to 0.1" % key)
			assert_almost_eq(rbc, snappedf(rbc, 0.01), 0.0001, "RBC is displayed to 0.01")


func test_review_action_precedence() -> void:
	assert_eq(AnalyzerLogic.review_action(false, false), "release")
	assert_eq(AnalyzerLogic.review_action(false, true), "smear")
	assert_eq(AnalyzerLogic.review_action(true, false), "investigate")
	assert_eq(AnalyzerLogic.review_action(true, true), "investigate")
