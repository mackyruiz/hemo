extends GutTest


func test_pick_gives_three_unique_items_per_bin() -> void:
	var bins_by_name: Dictionary = {}
	for item: Dictionary in SafetySort.ITEMS:
		bins_by_name[item["name"]] = item["bin"]
	for seed_value in range(1, 51):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var chips: Array[Dictionary] = SafetySort.pick(rng)
		assert_eq(chips.size(), 12)
		var names: Dictionary = {}
		var per_bin: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
		for chip: Dictionary in chips:
			names[chip["name"]] = true
			per_bin[int(chip["bin"])] += 1
			assert_eq(chip["bin"], bins_by_name[chip["name"]])
		assert_eq(names.size(), 12)
		assert_eq(per_bin, {0: 3, 1: 3, 2: 3, 3: 3})
