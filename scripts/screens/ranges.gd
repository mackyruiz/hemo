extends Control


func _ready() -> void:
	var page: Array = UI.page("Reference ranges")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("Adult reference ranges used in HemoShift. Reference ranges vary between laboratories.", "MutedLabel"))
	content.add_child(ReportTable.ranges_table())
