extends Control
## Practice deliberately ignores career unlocks.

const BENCHES := [
	{"id": "knowledge", "name": "Knowledge"},
	{"id": "morphology", "name": "Morphology"},
	{"id": "differential", "name": "Differential"},
	{"id": "cbc", "name": "CBC review"},
	{"id": "coag", "name": "Coagulation"},
	{"id": "qc", "name": "Quality control"},
	{"id": "micro", "name": "Microbiology"},
	{"id": "urinalysis", "name": "Urinalysis"},
	{"id": "blood_bank", "name": "Blood bank"},
	{"id": "immuno", "name": "Immunology"},
	{"id": "chem", "name": "Chemistry"},
	{"id": "safety", "name": "Lab safety"},
]

var _bench: String = "knowledge"
var _tier: int = 1
var _topic: String = ""
var _topic_section: VBoxContainer


func _ready() -> void:
	_tier = XpRules.tier_for_level(Progress.level())
	var page: Array = UI.page("Practice")
	add_child(page[0])
	var column: VBoxContainer = page[1]
	column.add_child(UI.label("Choose any bench and tier. Practice earns XP just like a career shift.", "MutedLabel"))
	column.add_child(UI.label("Bench", "TitleLabel"))
	var bench_group := ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	for entry in BENCHES:
		var id: String = String(entry["id"])
		var button := UI.button(String(entry["name"]), _select_bench.bind(id), "SecondaryButton")
		button.toggle_mode = true
		button.button_group = bench_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggled.connect(_toggle_text.bind(button, String(entry["name"])))
		button.button_pressed = id == _bench
		grid.add_child(button)
	column.add_child(UI.label("Tier", "TitleLabel"))
	var tier_group := ButtonGroup.new()
	var tiers := UI.hbox()
	column.add_child(tiers)
	for tier in range(1, 4):
		var button := UI.button("Tier %d" % tier, _select_tier.bind(tier), "SecondaryButton")
		button.toggle_mode = true
		button.button_group = tier_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggled.connect(_toggle_text.bind(button, "Tier %d" % tier))
		button.button_pressed = tier == _tier
		tiers.add_child(button)
	_topic_section = UI.vbox()
	column.add_child(_topic_section)
	_topic_section.add_child(UI.label("Knowledge topic", "TitleLabel"))
	var topic_group := ButtonGroup.new()
	var topics: Array[Dictionary] = [{"id": "", "name": "Any topic"}]
	for topic_id: String in Topics.NAMES:
		topics.append({"id": topic_id, "name": Topics.NAMES[topic_id]})
	for entry in topics:
		var id: String = String(entry["id"])
		var button := UI.button(String(entry["name"]), _select_topic.bind(id), "SecondaryButton")
		button.toggle_mode = true
		button.button_group = topic_group
		button.toggled.connect(_toggle_text.bind(button, String(entry["name"])))
		button.button_pressed = id == _topic
		_topic_section.add_child(button)
	column.add_child(UI.button("Start practice", _start_practice))


func _select_bench(id: String) -> void:
	_bench = id
	_topic_section.visible = id == "knowledge"


func _select_tier(tier: int) -> void:
	_tier = tier


func _select_topic(id: String) -> void:
	_topic = id


func _start_practice() -> void:
	Nav.go("shift", {"mode": "practice", "bench": _bench, "tier": _tier, "topic": _topic if _bench == "knowledge" else ""})


func _toggle_text(pressed: bool, button: Button, caption: String) -> void:
	button.text = ("✓ " if pressed else "") + caption
