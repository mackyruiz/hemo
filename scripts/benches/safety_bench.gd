extends Control
## Lab waste sort: place each item in the container it belongs in.

signal finished(result: Dictionary)

var _rng := RandomNumberGenerator.new()


func start(_task: Dictionary) -> void:
	_rng.seed = Time.get_ticks_usec()
	var chips: Array[Dictionary] = SafetySort.pick(_rng)
	var sort := ChipSort.new()
	sort.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sort)
	sort.setup("Lab waste sort", "Tap an item in the list, then tap the container it belongs in at the bottom. Tap a placed item to pick it up again.", SafetySort.BINS, chips, _rng, str(Content.generated_sources.get("safety:waste", "")), "item", "container", SafetySort.BIN_ART)
	sort.checked.connect(func(results: Array[bool]):
		var correct: int = 0
		for r: bool in results:
			Progress.record_topic_only("safety", r)
			if r:
				correct += 1
		sort.column.add_child(UI.button("Next", func(): finished.emit({"correct": correct, "total": chips.size(), "xp": XpRules.xp_for_sort(correct)}))))
