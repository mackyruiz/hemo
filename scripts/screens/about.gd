extends Control


func _ready() -> void:
	var page: Array = UI.page("About HemoShift")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("HemoShift helps MLT students and interns review hematology for the certification exam required for California MLT licensure. CDPH Laboratory Field Services accepts the ASCP BOC MLT (U.S. version) and AAB MLT certification exams. Content follows the ASCP BOC MLT content guideline for Hematology (physiology, disease states, laboratory testing, hemostasis)."))
	content.add_child(UI.label("Not affiliated with or endorsed by ASCP, AAB, or CDPH. For study only; not medical advice. Reference ranges vary between laboratories.", "MutedLabel"))
