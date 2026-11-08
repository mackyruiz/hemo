extends Control
## Coagulation cases and tap-to-sort coagulation pathway practice.

signal finished(result: Dictionary)

const CASE_BENCH := preload("res://scripts/benches/cbc_bench.gd")
const BINS := ["Intrinsic (APTT only)", "Extrinsic (PT only)", "Common (PT and APTT)", "Not detected by PT/APTT"]
const CHIPS := [
	{"name": "XII", "bin": 0}, {"name": "XI", "bin": 0},
	{"name": "IX", "bin": 0}, {"name": "VIII", "bin": 0},
	{"name": "Prekallikrein", "bin": 0}, {"name": "HMWK", "bin": 0},
	{"name": "VII", "bin": 1}, {"name": "Tissue factor", "bin": 1},
	{"name": "X", "bin": 2}, {"name": "V", "bin": 2},
	{"name": "II (prothrombin)", "bin": 2}, {"name": "I (fibrinogen)", "bin": 2},
	{"name": "XIII", "bin": 3}, {"name": "Protein C", "bin": 3},
]


func start(task: Dictionary) -> void:
	if String(task.get("variant", "case")) != "cascade":
		var case_view := CASE_BENCH.new()
		case_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(case_view)
		case_view.finished.connect(func(result: Dictionary): finished.emit(result))
		case_view.start(task)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()
	var sort := ChipSort.new()
	sort.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sort)
	sort.setup("Coagulation pathway sort", "Tap a factor in the list, then tap the pathway it belongs to at the bottom. Tap a placed factor to pick it up again.", BINS, CHIPS, rng, str(Content.generated_sources.get("coag:cascade", "")), "factor", "pathway")
	sort.checked.connect(func(results: Array[bool]):
		var correct: int = 0
		for r: bool in results:
			Progress.record_topic_only("hemo", r)
			if r:
				correct += 1
		sort.column.add_child(UI.button("Next", func(): finished.emit({"correct": correct, "total": CHIPS.size(), "xp": XpRules.xp_for_sort(correct)}))))
