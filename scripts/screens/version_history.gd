extends Control
## Dated project milestones, identified by their Git revision rather than invented release numbers.

const ENTRIES := [
	{"date": "2026-11-04", "revision": "0e60c1e", "title": "Full MLT subject coverage", "notes": "Blood banking, chemistry, microbiology, urinalysis, immunology and lab safety question banks and benches; Board Sim now mirrors the 100-question MLT exam."},
	{"date": "2026-11-03", "revision": "ff5977b", "title": "Real cell photography", "notes": "Photomicrographs with yellow target indicators replace cell drawings on study surfaces. Added new photos and removed the drawn smear-search game."},
	{"date": "2026-11-02", "revision": "e771383", "title": "Home screen tiles", "notes": "Illustrated navigation tiles for Practice, Board Sim, Lab Floor, Cell Atlas and Flashcards."},
	{"date": "2026-11-02", "revision": "45e5d7b", "title": "Study aids", "notes": "Flag questions for review and study cells and terms with spaced-repetition flashcards."},
	{"date": "2026-11-01", "revision": "c15602c", "title": "Lab Floor dialog fix", "notes": "Fixed the Lab Floor LIS dialog so results can be reviewed."},
	{"date": "2026-11-01", "revision": "cec7239", "title": "Lab Floor", "notes": "A walkable lab with microscope, specimen receiving, centrifuge, ESR and analyzer stations."},
	{"date": "2026-11-01", "revision": "94d5405", "title": "Touch scrolling", "notes": "Improved tap handling while scrolling on touch screens."},
	{"date": "2026-11-01", "revision": "29c4ca9", "title": "Hints and sources", "notes": "50/50 hints and verified Read more source links."},
	{"date": "2026-11-01", "revision": "26aeb79", "title": "HemoShift launch", "notes": "Hematology lab shifts, exam practice and study tools for MLT learners."},
]


func _ready() -> void:
	var page: Array = UI.page("Version history")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("Project updates, newest first. Versions are identified by their Git revision; there are no numbered releases yet.", "MutedLabel"))
	for entry in ENTRIES:
		var card := UI.card()
		var column := UI.vbox(8)
		card.add_child(column)
		column.add_child(UI.label("%s · %s" % [entry["date"], entry["revision"]], "MutedLabel"))
		column.add_child(UI.label(entry["title"], "TitleLabel"))
		column.add_child(UI.label(entry["notes"]))
		content.add_child(card)
