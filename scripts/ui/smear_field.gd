class_name SmearField
extends Control
## A reproducible, non-overlapping field with touch-sized cells.

signal tapped(is_target: bool)

var hits: int = 0
var misses: int = 0
var target_count: int = 0

var _target_id: String = "normal_rbc"
var _layout_seed: int = 0
var _cells: Array[Dictionary] = []
var _miss_marks: Array[Vector2] = []
var _revealed: bool = false
var _cell_scale: float = 42.0
var _field_background: StyleBoxFlat


func setup(target_morph_id: String, count: int, rng: RandomNumberGenerator) -> void:
	_target_id = target_morph_id
	target_count = clampi(count, 2, 5)
	_layout_seed = rng.randi()
	hits = 0
	misses = 0
	_revealed = false
	_miss_marks.clear()
	_cells.clear()
	custom_minimum_size = Vector2(0, 520)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_layout()
	queue_redraw()


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, 520.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	_layout()


func _on_resized() -> void:
	# Regenerate from the same seed, retaining hit state by cell index.
	_layout()
	queue_redraw()


func _target_art() -> Dictionary:
	var entity: Dictionary = Content.morph.get(_target_id, {})
	var art: Variant = entity.get("art", {})
	return art if art is Dictionary else {}


func _layout() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _layout_seed
	var old_cells: Array[Dictionary] = _cells
	_cells = []
	var target_art: Dictionary = _target_art()
	# A fixed size across the field makes all cells equally easy to tap.
	_cell_scale = minf(42.0, size.x / 8.0)
	var target_radius: float = CellArt.cell_radius(target_art, _cell_scale)
	var normal_radius: float = CellArt.cell_radius({}, _cell_scale)
	var target_is_field: bool = str(target_art.get("kind", "rbc")) == "field"
	var total: int = 35 + target_count
	var kinds: Array[bool] = []
	for i in range(total):
		kinds.append(i < target_count)
	for i in range(total - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: bool = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = temp
	for i in range(total):
		var radius: float = target_radius if kinds[i] else normal_radius
		var hit_radius: float = radius if kinds[i] and target_is_field else radius / 1.4
		var candidate := Vector2.ZERO
		var placed: bool = false
		for attempt in range(1200):
			candidate = Vector2(rng.randf_range(radius + 4.0, maxf(radius + 4.0, size.x - radius - 4.0)), rng.randf_range(radius + 4.0, maxf(radius + 4.0, size.y - radius - 4.0)))
			placed = true
			for other in _cells:
				var other_pos: Vector2 = other["pos"]
				var other_hit_radius: float = other["hit_radius"]
				# Arrangement bounds already include every constituent cell;
				# only ordinary-cell radii contain the 1.4 drawing padding.
				# Separate the actual hit circles, including around fields.
				if candidate.distance_to(other_pos) < hit_radius + other_hit_radius:
					placed = false
					break
			if placed:
				break
		if not placed:
			# At unusually narrow widths, enlarge the scrollable canvas rather
			# than overlap target hit regions or silently omit cells.
			custom_minimum_size.y += _cell_scale * 2.0
			return
		var was_hit: bool = i < old_cells.size() and bool(old_cells[i].get("hit", false))
		_cells.append({"pos": candidate, "radius": radius, "hit_radius": hit_radius, "target": kinds[i], "hit": was_hit, "seed": rng.randi()})


func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var target_art: Dictionary = _target_art()
	var normal_art: Dictionary = {"kind": "rbc", "shape": "disc", "pallor": 0.33, "color": "#D98C8C"}
	for cell in _cells:
		var pos: Vector2 = cell["pos"]
		var is_target: bool = cell["target"]
		CellArt.draw_cell(self, target_art if is_target else normal_art, pos, _cell_scale, int(cell["seed"]))
		var radius: float = float(cell["radius"]) * 0.82
		if bool(cell["hit"]):
			draw_arc(pos, radius + 3.0, 0.0, TAU, 40, ThemeBuilder.SUCCESS, 3.0, true)
			_draw_mark(pos, "✓", ThemeBuilder.SUCCESS)
		elif _revealed and is_target:
			draw_arc(pos, radius + 3.0, 0.0, TAU, 40, ThemeBuilder.ACCENT, 3.0, true)
			_draw_mark(pos, "○", ThemeBuilder.ACCENT)
	for normalized in _miss_marks:
		var pos: Vector2 = normalized * size
		draw_arc(pos, 14.0, 0.0, TAU, 24, ThemeBuilder.ERROR, 2.0, true)
		_draw_mark(pos, "✗", ThemeBuilder.ERROR)


func _background() -> StyleBoxFlat:
	if _field_background == null:
		_field_background = StyleBoxFlat.new()
		_field_background.bg_color = Color("#FFF9F3")
		_field_background.border_color = Color("#D9D0D4")
		_field_background.set_border_width_all(1)
		_field_background.set_corner_radius_all(12)
	return _field_background


func _draw_mark(pos: Vector2, text: String, color: Color) -> void:
	draw_string(get_theme_default_font(), pos + Vector2(-8, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)


func _gui_input(event: InputEvent) -> void:
	if _revealed:
		return
	# Touch events also generate an emulated mouse event on mobile. Count once.
	if event is InputEventMouseButton and event.device == -1:
		return
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	accept_event()
	var nearest: int = -1
	var nearest_distance: float = INF
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var pos: Vector2 = cell["pos"]
		var distance: float = point.distance_to(pos)
		if distance <= float(cell["hit_radius"]) and distance < nearest_distance:
			nearest = i
			nearest_distance = distance
	if nearest >= 0 and bool(_cells[nearest]["hit"]):
		return
	var is_target: bool = nearest >= 0 and bool(_cells[nearest]["target"])
	if is_target:
		_cells[nearest]["hit"] = true
		hits += 1
	else:
		misses += 1
		_miss_marks.append(point / size)
	queue_redraw()
	tapped.emit(is_target)


func reveal() -> void:
	_revealed = true
	queue_redraw()
