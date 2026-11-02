class_name ReportTable
extends RefCounted
## Report grids share Content's adult reference intervals and flag semantics.

const CBC_ORDER := ["WBC", "RBC", "HGB", "HCT", "MCV", "MCH", "MCHC", "RDW", "PLT", "RETIC"]
const COAG_ORDER := ["PT", "INR", "APTT", "FIB", "DDIMER", "TT", "PLT", "MIX_PT", "MIX_APTT"]


static func build(kind: String, results: Dictionary, sex: String) -> Control:
	var grid: GridContainer = _grid()
	for heading in ["Test", "Result", "Flag", "Ref range", "Unit"]:
		grid.add_child(_text(heading, true))
	var order: Array = CBC_ORDER if kind == "cbc" else COAG_ORDER
	for key in order:
		if not results.has(key):
			continue
		var value: Variant = results[key]
		if str(key).begins_with("MIX_"):
			var name: String = "Mixing study (%s)" % str(key).trim_prefix("MIX_")
			var interpretation: String = "—"
			if value != null:
				interpretation = "Corrected" if str(value) == "corrected" else "Not corrected"
			_add_row(grid, name, interpretation, "", "—", "—")
			continue
		var reference: Dictionary = Content.ranges.get(key, {})
		var flag: String = "" if value == null else Content.flag(key, float(value), sex)
		var result: String = "—" if value == null else str(value)
		_add_row(grid, key, result, flag, _range_text(reference, sex), str(reference.get("unit", "—")))
	return grid


static func ranges_table() -> Control:
	var grid: GridContainer = _grid()
	grid.columns = 3
	for heading in ["Test", "Adult reference range", "Unit"]:
		grid.add_child(_text(heading, true))
	var keys: Array = CBC_ORDER.duplicate()
	for key in COAG_ORDER:
		if not keys.has(key) and not str(key).begins_with("MIX_"):
			keys.append(key)
	for key in keys:
		var reference: Dictionary = Content.ranges.get(key, {})
		grid.add_child(_text(str(key)))
		var interval: String
		if reference.has("M") or reference.has("F"):
			interval = "M: %s\nF: %s" % [_range_text(reference, "M"), _range_text(reference, "F")]
		else:
			interval = _range_text(reference, "")
		grid.add_child(_text(interval))
		grid.add_child(_text(str(reference.get("unit", "—"))))
	return grid


static func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 12)
	return grid


static func _range_text(reference: Dictionary, sex: String) -> String:
	var interval: Dictionary = reference
	if reference.has("M") or reference.has("F"):
		interval = reference.get(sex, {})
	if not interval.has("low") or not interval.has("high"):
		return "—"
	return "%s–%s" % [str(interval["low"]), str(interval["high"])]


static func _text(value: String, bold: bool = false) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "[b]%s[/b]" % value if bold else value
	# Equal-width columns can wrap even on a narrow portrait display.
	label.custom_minimum_size.x = 24
	return label


static func _add_row(grid: GridContainer, name: String, result: String, flag: String, reference: String, unit: String) -> void:
	grid.add_child(_text(name))
	var result_label: RichTextLabel = _text(result)
	if result == "—":
		result_label.tooltip_text = "Not performed"
	grid.add_child(result_label)
	var flag_label: RichTextLabel = _text(flag, not flag.is_empty())
	if not flag.is_empty():
		flag_label.add_theme_color_override("default_color", ThemeBuilder.ERROR if flag == "H" else ThemeBuilder.ACCENT)
		flag_label.tooltip_text = "Above reference range" if flag == "H" else "Below reference range"
	grid.add_child(flag_label)
	grid.add_child(_text(reference))
	grid.add_child(_text(unit))
