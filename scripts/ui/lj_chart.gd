class_name LJChart
extends Control
## Two-level Levey–Jennings plots, expressed in SD units around each mean.

var _qc_data: Dictionary = {}


func setup(qc_data: Dictionary) -> void:
	_qc_data = qc_data
	custom_minimum_size = Vector2(0, 640)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	custom_minimum_size.y = maxf(640.0, custom_minimum_size.y)
	resized.connect(queue_redraw)


func _draw() -> void:
	var levels: Variant = _qc_data.get("levels", [])
	if not levels is Array or levels.is_empty():
		return
	var panel_height: float = size.y / levels.size()
	for i in range(levels.size()):
		var level: Variant = levels[i]
		if level is Dictionary:
			_draw_level(level, Rect2(0.0, panel_height * i, size.x, panel_height))


func _draw_level(level: Dictionary, bounds: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var title: String = str(level.get("name", "Control")) + " · " + str(_qc_data.get("analyte", ""))
	var mean: float = float(level.get("mean", 0.0))
	var sd: float = float(level.get("sd", 1.0))
	var subtitle: String = "Mean %s · SD %s %s" % [str(mean), str(sd), str(_qc_data.get("unit", ""))]
	draw_string(font, bounds.position + Vector2(8, 23), title, HORIZONTAL_ALIGNMENT_LEFT, bounds.size.x - 16.0, 20, ThemeBuilder.TEXT)
	draw_string(font, bounds.position + Vector2(8, 46), subtitle, HORIZONTAL_ALIGNMENT_LEFT, bounds.size.x - 16.0, 17, ThemeBuilder.MUTED)
	var plot := Rect2(bounds.position + Vector2(46, 64), Vector2(maxf(1, bounds.size.x - 62), maxf(1, bounds.size.y - 108)))
	draw_rect(plot, ThemeBuilder.SURFACE)
	for z in range(-3, 4):
		var y: float = _y(float(z), plot)
		var color: Color = ThemeBuilder.MUTED if z == 0 else Color("#DAD4D7")
		if absi(z) >= 2:
			color = Color("#DFC5CB")
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), color, 1.4 if z == 0 else 1.0, true)
		var label: String = "Mean" if z == 0 else ("+%ds" % z if z > 0 else "%ds" % z)
		draw_string(font, Vector2(bounds.position.x + 2, y + 5), label, HORIZONTAL_ALIGNMENT_LEFT, 43, 15, ThemeBuilder.MUTED)
	draw_rect(plot, Color("#B7ADB4"), false, 1.0)
	var z_values: Variant = level.get("z", [])
	if not z_values is Array or z_values.is_empty():
		return
	var count: int = z_values.size()
	var points := PackedVector2Array()
	for i in range(count):
		var z: float = float(z_values[i])
		points.append(Vector2(_x(i, count, plot), _y(clampf(z, -4, 4), plot)))
	if points.size() > 1:
		draw_polyline(points, ThemeBuilder.ACCENT, 1.8, true)
	for i in range(count):
		var z: float = float(z_values[i])
		var outlier: bool = absf(z) > 2.0
		var color: Color = ThemeBuilder.ERROR if outlier else ThemeBuilder.ACCENT
		var radius: float = 5.5 if i == count - 1 else 3.5
		draw_circle(points[i], radius, color)
		if i == count - 1:
			draw_arc(points[i], radius + 3, 0, TAU, 24, color, 1.5, true)
		if outlier:
			# Numeric annotation makes the outlier meaningful without color.
			var text: String = "%d: %+.1fs" % [i + 1, z]
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var x: float = clampf(points[i].x - width * 0.5, plot.position.x, maxf(plot.position.x, plot.end.x - width))
			var y: float = points[i].y - 10 if z > 0 else points[i].y + 21
			y = clampf(y, plot.position.y + 15, plot.end.y - 3)
			draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	for i in range(count):
		if i == 0 or (i + 1) % 5 == 0 or i == count - 1:
			draw_string(font, Vector2(_x(i, count, plot) - 7, plot.end.y + 21), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ThemeBuilder.MUTED)
	draw_string(font, Vector2(plot.position.x + plot.size.x * 0.5 - 15, plot.end.y + 40), "Run", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ThemeBuilder.MUTED)


func _x(index: int, count: int, plot: Rect2) -> float:
	return plot.position.x + plot.size.x * float(index) / maxf(1.0, count - 1.0)


func _y(z: float, plot: Rect2) -> float:
	return plot.position.y + (4.0 - z) / 8.0 * plot.size.y
