extends GutTest


func test_real_profiles_generate_valid_differentials() -> void:
	var profiles: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/diff_profiles.json"))
	assert_eq(profiles.size(), 8)
	for profile: Dictionary in profiles:
		for seed_value in range(1, 21):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var result: Dictionary = DiffGenerator.generate(profile, rng)
			var counts: Dictionary = result["counts"]
			var pct: Dictionary = profile["pct"]
			var total: int = 0
			for cls: String in counts:
				total += int(counts[cls])
				assert_true(pct.has(cls), str(profile["id"]) + " contains only supported classes")
				assert_gt(int(pct.get(cls, 0)), 0)
				assert_gt(int(counts[cls]), 0)
			assert_eq(total, 100)
			var nrbc: int = result["nrbc"]
			var sequence: Array = result["sequence"]
			assert_eq(sequence.size(), 100 + nrbc)
			assert_between(nrbc, int(profile["nrbc"][0]), int(profile["nrbc"][1]))
			assert_between(float(result["wbc"]), float(profile["wbc"][0]), float(profile["wbc"][1]))
			assert_almost_eq(float(result["wbc"]) * 10.0, roundf(float(result["wbc"]) * 10.0), 0.00001)
			assert_eq(result["profile_id"], profile["id"])
			var observed: Dictionary = {}
			for cls: String in sequence:
				observed[cls] = int(observed.get(cls, 0)) + 1
				if cls != "nrbc":
					assert_gt(int(pct.get(cls, 0)), 0)
			assert_eq(int(observed.get("nrbc", 0)), nrbc)
			for cls: String in counts:
				assert_eq(int(observed.get(cls, 0)), int(counts[cls]))


func test_generation_uses_only_injected_rng() -> void:
	var profiles: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/diff_profiles.json"))
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 1337
	rng_b.seed = 1337
	assert_eq(DiffGenerator.generate(profiles[6], rng_a), DiffGenerator.generate(profiles[6], rng_b))
