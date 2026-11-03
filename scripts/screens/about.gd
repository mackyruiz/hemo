extends Control


func _ready() -> void:
	var page: Array = UI.page("About HemoShift")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	content.add_child(UI.label("HemoShift helps MLT students and interns review every content area of the certification exam required for California MLT licensure: hematology, blood banking, chemistry, microbiology, urinalysis and body fluids, immunology, and laboratory operations including safety. CDPH Laboratory Field Services accepts the ASCP BOC MLT (U.S. version) and AAB MLT certification exams. Content follows the ASCP BOC MLT examination content guideline (revised June 9, 2026)."))
	content.add_child(UI.label("Not affiliated with or endorsed by ASCP, AAB, or CDPH. For study only; not medical advice. Reference ranges vary between laboratories.", "MutedLabel"))
