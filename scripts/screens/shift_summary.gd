extends Control

const TOPIC_NAMES := {
	"phys": "Physiology", "rbc": "RBC disorders", "wbc": "WBC disorders",
	"plt": "Platelet disorders", "lab": "Lab testing & morphology",
	"hemo": "Hemostasis", "qc": "QC & lab operations",
}
const BENCH_NAMES := {
	"knowledge": "Knowledge", "morphology": "Morphology", "differential": "Differential",
	"cbc": "CBC review", "coag": "Coagulation", "qc": "Quality control",
}

var _params: Dictionary = {}


func setup(params: Dictionary) -> void:
	_params = params.duplicate(true)


func _ready() -> void:
	var page: Array = UI.page("Shift complete", false)
	add_child(page[0])
	var column: VBoxContainer = page[1]
	var card := UI.card()
	var results := UI.vbox()
	card.add_child(results)
	results.add_child(UI.label("%d%% accuracy" % int(round(float(_params.get("accuracy", 0.0)) * 100.0)), "TitleLabel"))
	results.add_child(UI.label("%d of %d correct" % [int(_params.get("correct", 0)), int(_params.get("total", 0))]))
	results.add_child(UI.label("+%d XP earned" % int(_params.get("xp_gained", 0))))
	results.add_child(UI.label("Includes the shift completion bonus. An accuracy bonus is awarded at 80% or higher.", "MutedLabel"))
	column.add_child(card)
	var old_level: int = int(_params.get("old_level", Progress.level()))
	var new_level: int = int(_params.get("new_level", Progress.level()))
	if new_level > old_level:
		var level_card := UI.card()
		var level_text := UI.vbox()
		level_card.add_child(level_text)
		level_text.add_child(UI.label("Level up! Level %d" % new_level, "TitleLabel"))
		level_text.add_child(UI.label(XpRules.rank_for_level(new_level)))
		var old_benches: Array[String] = XpRules.unlocked_benches(old_level)
		var new_benches: Array[String] = XpRules.unlocked_benches(new_level)
		for bench in new_benches:
			if not old_benches.has(bench):
				level_text.add_child(UI.label("New bench unlocked: " + String(BENCH_NAMES[bench])))
		column.add_child(level_card)
	var weakest: String = String(_params.get("weakest_topic", ""))
	if not weakest.is_empty():
		column.add_child(UI.label("Weakest topic: " + String(TOPIC_NAMES.get(weakest, weakest))))
	column.add_child(UI.button("Another shift", _another_shift))
	column.add_child(UI.button("Back to lab", func(): Nav.go("hub"), "SecondaryButton"))


func _another_shift() -> void:
	var mode: String = String(_params.get("mode", "career"))
	if mode == "practice" and String(_params.get("bench", "")).is_empty():
		Nav.replace("practice")
		return
	Nav.replace("shift", {
		"mode": mode, "bench": String(_params.get("bench", "")),
		"tier": int(_params.get("tier", 0)), "topic": String(_params.get("topic", "")),
	})
