extends Control
## Home screen: rank, Start Shift, bench grid, navigation, banners.

const HEME_BENCHES := [
	{"id": "knowledge", "name": "Knowledge", "desc": "Exam-style questions and lab math drills"},
	{"id": "morphology", "name": "Morphology", "desc": "Identify cells and their clinical associations"},
	{"id": "differential", "name": "Differential", "desc": "Count 100 WBCs and report the diff"},
	{"id": "cbc", "name": "CBC", "desc": "Interpret CBC reports and indices"},
	{"id": "coag", "name": "Coagulation", "desc": "Coag cases and the cascade sort"},
	{"id": "qc", "name": "QC", "desc": "Levey-Jennings charts and Westgard rules"},
]
const SUBJECT_BENCHES := [
	{"id": "micro", "name": "Microbiology", "desc": "Gram stains and organism workups"},
	{"id": "urinalysis", "name": "Urinalysis", "desc": "Dipstick and sediment interpretation"},
	{"id": "blood_bank", "name": "Blood bank", "desc": "ABO/Rh typing and compatible units"},
	{"id": "immuno", "name": "Immunology", "desc": "Hepatitis B serology panels"},
	{"id": "chem", "name": "Chemistry", "desc": "Chemistry calculations"},
	{"id": "safety", "name": "Lab safety", "desc": "Sort lab waste safely"},
]

const FEATURES := [
	{"route": "practice", "title": "Practice", "desc": "Any bench, any time", "art": "practice", "tint": "#B3263E"},
	{"route": "exam", "title": "Board Sim", "desc": "100-item timed mock exam", "art": "board_sim", "tint": "#4A5BA8"},
	{"route": "lab_floor", "title": "Lab Floor", "desc": "Walk the lab and run stations", "art": "lab_floor", "tint": "#2E8B57"},
	{"route": "atlas", "title": "Cell Atlas", "desc": "Every cell, photographed", "art": "atlas", "tint": "#8E4A9E"},
	{"route": "flashcards", "title": "Flashcards", "desc": "Cells and terms with spaced repetition", "art": "flashcards", "tint": "#C0731B"},
]


func _ready() -> void:
	var p: Array = UI.page("HemoShift", false)
	add_child(p[0])
	var content: VBoxContainer = p[1]
	var lvl: int = Progress.level()
	var xp: int = Progress.xp()

	content.add_child(UI.label("Lab shifts for MLT certification exam prep", "MutedLabel"))

	content.add_child(_rank_card(lvl, xp))

	var start := UI.button("Start Shift", func(): Nav.go("shift", {"mode": "career"}))
	start.custom_minimum_size.y = 84
	content.add_child(start)

	content.add_child(UI.label("Hematology benches", "TitleLabel"))
	content.add_child(_bench_grid(lvl, HEME_BENCHES))
	content.add_child(UI.label("More subjects", "TitleLabel"))
	content.add_child(_bench_grid(lvl, SUBJECT_BENCHES))

	content.add_child(UI.label("Study & explore", "TitleLabel"))
	content.add_child(_feature_tiles())

	content.add_child(UI.button("Flagged questions (%d)" % Progress.flagged().size(), func(): Nav.go("flagged"), "SecondaryButton"))
	content.add_child(UI.button("My Progress", func(): Nav.go("progress"), "SecondaryButton"))
	content.add_child(UI.button("Settings", func(): Nav.go("settings"), "SecondaryButton"))

	if not Progress.is_persistent():
		content.add_child(_banner("This browser isn't saving your progress (private mode or blocked storage)."))
	if not Content.load_errors.is_empty():
		content.add_child(_banner("Some content failed to load."))
	if DebugMode.unlock_all():
		content.add_child(_banner("DEBUG BUILD — all benches unlocked, level forced to %d." % XpRules.MAX_LEVEL))

	content.add_child(_footer())

	if Progress.consume_recovered():
		UI.toast(self, "Your saved progress was unreadable and has been reset. A backup was kept.")


func _footer() -> VBoxContainer:
	var footer := UI.vbox(8)
	footer.add_child(HSeparator.new())
	var links := UI.hbox(12)
	links.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(links)
	var history := UI.button("Version history", func(): Nav.go("version_history"), "SecondaryButton")
	history.custom_minimum_size.x = 220
	history.flat = true
	links.add_child(history)
	var github := UI.button("", func(): OS.shell_open("https://github.com/mackyruiz/hemo"), "SecondaryButton")
	github.name = "GitHubProjectLink"
	github.icon = preload("res://assets/icons/github.svg")
	github.custom_minimum_size = Vector2(64, 64)
	github.tooltip_text = "View HemoShift on GitHub"
	github.accessibility_name = "HemoShift GitHub project"
	github.flat = true
	links.add_child(github)
	return footer


func _banner(text: String) -> PanelContainer:
	var c := UI.card()
	c.add_theme_stylebox_override("panel", ThemeBuilder._box(Color("#FBE9E7"), 14, ThemeBuilder.ERROR, 2, 16))
	c.add_child(UI.label("⚠ " + text))
	return c


func _rank_card(lvl: int, xp: int) -> PanelContainer:
	var card := UI.card()
	var v := UI.vbox(8)
	card.add_child(v)
	v.add_child(UI.label(XpRules.rank_for_level(lvl), "TitleLabel"))
	v.add_child(UI.label("Level %d" % lvl))

	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 28
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	var base: int = XpRules.threshold(lvl)
	var nxt: int = XpRules.threshold(lvl + 1)
	if lvl >= 30:
		bar.max_value = 1.0
		bar.value = 1.0
		v.add_child(bar)
		v.add_child(UI.label("%d XP · max level" % xp, "MutedLabel"))
	else:
		bar.max_value = float(nxt - base)
		bar.value = float(xp - base)
		v.add_child(bar)
		v.add_child(UI.label("%d XP · %d xp to next level" % [xp, nxt - xp], "MutedLabel"))
	var due: int = Progress.due_count()
	if due > 0:
		v.add_child(UI.label("%d item%s due for review" % [due, "" if due == 1 else "s"], "MutedLabel"))
	return card


func _bench_grid(lvl: int, benches: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tier: int = XpRules.tier_for_level(lvl)
	for b in benches:
		var d: Dictionary = b
		var id: String = d["id"]
		var unlock: int = XpRules.BENCH_UNLOCK[id]
		var open: bool = lvl >= unlock

		var card := UI.card()
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(6)
		card.add_child(v)
		v.add_child(UI.label(d["name"] as String, "TitleLabel"))
		var desc := UI.label(d["desc"] as String, "MutedLabel")
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(desc)
		if open:
			UI.tappable(card, func(): Nav.go("shift", {"mode": "practice", "bench": id, "tier": tier}))
			v.add_child(UI.label("✓ Unlocked"))
			v.add_child(UI.button("Practice", func(): Nav.go("shift", {"mode": "practice", "bench": id, "tier": tier})))
		else:
			v.add_child(UI.label("Unlocks at Level %d" % unlock))
			var locked := UI.button("Locked", func(): pass, "SecondaryButton")
			locked.disabled = true
			v.add_child(locked)
		grid.add_child(card)
	return grid


func _feature_tiles() -> VBoxContainer:
	var grid := UI.vbox(12)
	var tiles: Array[HubTile] = []
	for f in FEATURES:
		var route: String = f["route"]
		tiles.append(HubTile.make(f["title"], f["desc"], f["art"], Color(f["tint"]), func(): Nav.go(route)))
	for pair in [[0, 1], [2, 3]]:
		var row := UI.hbox(12)
		for i in pair:
			row.add_child(tiles[i])
		grid.add_child(row)

	var last := UI.hbox(12)
	last.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles[4].size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	last.add_child(tiles[4])
	grid.add_child(last)
	tiles[0].resized.connect(func(): tiles[4].custom_minimum_size.x = tiles[0].size.x)
	return grid
