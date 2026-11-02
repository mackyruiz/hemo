class_name CellArt
extends Control
## Shared, seeded Wright–Giemsa-style illustration renderer.

const UM_PER_UNIT := 7.5
const STUDY_SCALE_PX := 80.0
const RULER_HEIGHT := 48.0
const PHOTO_SCALE_NOTE := "Photos are not to scale — compare with a nearby normal RBC (≈7.5 µm)."

var descriptor: Dictionary = {}:
	set(value):
		descriptor = value
		_update_minimum()
		queue_redraw()
var seed: int = 0:
	set(value):
		seed = value
		queue_redraw()
var scale_px: float = 60.0:
	set(value):
		scale_px = maxf(1.0, value)
		_update_minimum()
		queue_redraw()
var ruler: bool = false:
	set(value):
		ruler = value
		_update_minimum()
		queue_redraw()


static func make(desc: Dictionary, cell_seed: int = 0, cell_scale_px: float = 60.0, with_ruler: bool = false) -> CellArt:
	var art := CellArt.new()
	art.descriptor = desc
	art.seed = cell_seed
	art.scale_px = cell_scale_px
	art.ruler = with_ruler
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _ready() -> void:
	resized.connect(queue_redraw)
	_update_minimum()


func _update_minimum() -> void:
	var cell_box: float = cell_radius(descriptor, scale_px) * 2.0 + 16.0
	if not ruler:
		custom_minimum_size = Vector2(cell_box, cell_box)
		return
	var px_per_um: float = scale_px / UM_PER_UNIT
	var ruler_px: float = ruler_um(_size_units(descriptor) * UM_PER_UNIT) * px_per_um
	custom_minimum_size = Vector2(maxf(cell_box, ruler_px * 2.0 + 16.0), cell_box + RULER_HEIGHT)


func _draw() -> void:
	var center := Vector2(size.x * 0.5, (size.y - (RULER_HEIGHT if ruler else 0.0)) * 0.5)
	var r: float = draw_cell(self, descriptor, center, scale_px, seed)
	if ruler:
		_draw_ruler(center, r)


func _draw_ruler(center: Vector2, r: float) -> void:
	var px_per_um: float = scale_px / UM_PER_UNIT
	var um: int = ruler_um(_size_units(descriptor) * UM_PER_UNIT)
	var ruler_px: float = um * px_per_um
	var x0: float = center.x - r
	if str(descriptor.get("kind", "rbc")) == "field":
		x0 = center.x - ruler_px * 0.5
	var y: float = size.y - RULER_HEIGHT + 10.0
	draw_line(Vector2(x0, y), Vector2(x0 + ruler_px, y), ThemeBuilder.TEXT, 2.0, true)
	var font: Font = get_theme_default_font()
	var font_size: int = int(get_theme_default_font_size() * 0.6)
	for i in range(um + 1):
		var x: float = x0 + i * px_per_um
		var height: float = 12.0 if i % 5 == 0 else 6.0
		draw_line(Vector2(x, y), Vector2(x, y + height), ThemeBuilder.TEXT, 1.2, true)
		if i % 5 == 0:
			var label: String = str(i)
			if i == um:
				label += "µm"
			draw_string(font, Vector2(x, y + height + font_size + 4), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, ThemeBuilder.MUTED)


static func ruler_um(diameter_um: float) -> int:
	return maxi(5, int(ceil((diameter_um + 1.0) / 5.0)) * 5)


static func _default_size(desc: Dictionary) -> float:
	var kind: String = str(desc.get("kind", "rbc"))
	if kind == "field":
		return 3.2
	return 1.6 if kind == "wbc" else (0.35 if kind == "platelet" else 1.0)


static func _size_units(desc: Dictionary) -> float:
	return maxf(0.1, _number(desc.get("size"), _default_size(desc)))


static func cell_radius(desc: Dictionary, cell_scale_px: float) -> float:
	var kind: String = str(desc.get("kind", "rbc"))
	if kind == "field":
		return cell_scale_px * 1.6
	var radius: float = _size_units(desc) * cell_scale_px * 0.5
	# Includes seed jitter and spicules/projections, keeping art clear of its bounds.
	return radius * 1.4


static func draw_cell(ci: CanvasItem, desc: Dictionary, pos: Vector2, cell_scale_px: float, cell_seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = cell_seed
	var rotation: float = rng.randf_range(-PI, PI)
	var kind: String = str(desc.get("kind", "rbc"))
	if kind == "field":
		_draw_field(ci, desc, pos, cell_scale_px, rng)
		return cell_scale_px * 1.6
	var r: float = cell_scale_px * 0.5 * _size_units(desc) * rng.randf_range(0.95, 1.05)
	match kind:
		"wbc":
			_draw_wbc(ci, desc, pos, r, rotation, rng)
		"platelet":
			_draw_platelet(ci, desc, pos, r, rng)
		_:
			_draw_rbc(ci, desc, pos, r, rotation, rng)
	return r


static func _number(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		var result: float = float(value)
		return result if is_finite(result) else fallback
	return fallback


static func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _array(value: Variant) -> Array:
	return value if value is Array else []


static func _color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String and Color.html_is_valid(value):
		return Color(value)
	return fallback


static func _at(p: Vector2, pos: Vector2, rotation: float) -> Vector2:
	return pos + p.rotated(rotation)


static func _polygon(ci: CanvasItem, points: PackedVector2Array, pos: Vector2, rotation: float, color: Color, rim: bool = true) -> void:
	if points.size() < 3:
		return
	var transformed := PackedVector2Array()
	for p in points:
		transformed.append(_at(p, pos, rotation))
	ci.draw_colored_polygon(transformed, color)
	if rim:
		transformed.append(transformed[0])
		ci.draw_polyline(transformed, color.darkened(0.18), 1.2, true)


static func _disc(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	ci.draw_circle(pos, r, color)
	ci.draw_arc(pos, r, 0.0, TAU, 48, color.darkened(0.18), 1.0, true)


static func _draw_rbc(ci: CanvasItem, desc: Dictionary, pos: Vector2, r: float, rotation: float, rng: RandomNumberGenerator) -> void:
	var shape: String = str(desc.get("shape", "disc"))
	var color: Color = _color(desc.get("color"), Color("#D98C8C"))
	var points: PackedVector2Array
	match shape:
		"sickle": points = CellShapes.sickle(r)
		"ellipse": points = CellShapes.ellipse(r * 1.15, r * 0.57)
		"teardrop": points = CellShapes.teardrop(r)
		"fragment": points = CellShapes.fragment(r, rng)
		"acanth": points = CellShapes.spiculated(r * 0.80, rng.randi_range(4, 8), r * 0.28, true, rng)
		"echino": points = CellShapes.spiculated(r * 0.87, rng.randi_range(16, 24), r * 0.12, false, rng)
		"bite": points = CellShapes.bite(r)
		"crystal":
			points = PackedVector2Array([Vector2(-r * 0.6, -r * 0.3), Vector2(r * 0.65, -r * 0.3), Vector2(r * 0.85, r * 0.15), Vector2(-r * 0.5, r * 0.3)])
		_: points = CellShapes.circle(r)
	var inclusions: Array = _array(desc.get("inclusions"))
	for inclusion in inclusions:
		if str(_dict(inclusion).get("type", "")) == "heinz":
			color = Color("#A7D0CB")
	_polygon(ci, points, pos, rotation, color)
	var pallor: float = clampf(_number(desc.get("pallor"), 0.33), 0.0, 0.85)
	var pale: Color = color.lerp(Color("#FCF1EB"), 0.72)
	if pallor > 0.0 and shape not in ["sphere", "sickle", "fragment", "crystal"]:
		var inner: PackedVector2Array = CellShapes.ellipse(r * pallor, r * pallor * 0.82)
		if shape == "ellipse":
			inner = CellShapes.ellipse(r * pallor * 1.2, r * pallor * 0.55)
		elif shape == "stomato":
			inner = CellShapes.ellipse(r * 0.55, r * 0.10)
		_polygon(ci, inner, pos, rotation, pale, false)
	if shape == "target":
		ci.draw_circle(pos, r * 0.18, color.darkened(0.10))
	for inclusion in inclusions:
		_draw_inclusion(ci, _dict(inclusion), pos, r, rotation, rng)
	var nucleus: Dictionary = _dict(desc.get("nucleus"))
	if not nucleus.is_empty():
		_draw_nucleus(ci, nucleus, pos, r, rotation, rng)


static func _random_point(rng: RandomNumberGenerator, r: float) -> Vector2:
	return Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * r


static func _draw_inclusion(ci: CanvasItem, inclusion: Dictionary, pos: Vector2, r: float, rotation: float, rng: RandomNumberGenerator) -> void:
	var purple := Color("#4D3B78")
	var blue := Color("#386899")
	var count: int = clampi(int(_number(inclusion.get("count"), 1)), 1, 40)
	match str(inclusion.get("type", "")):
		"howell_jolly":
			for i in range(count):
				ci.draw_circle(pos + _random_point(rng, r * 0.65), r * 0.11, purple)
		"stipple":
			for i in range(rng.randi_range(18, 28)):
				ci.draw_circle(pos + _random_point(rng, r * 0.85), r * 0.025, purple)
		"pappenheimer":
			var cluster: Vector2 = _at(Vector2(r * 0.65, 0), pos, rotation)
			for i in range(rng.randi_range(3, 6)):
				ci.draw_circle(cluster + _random_point(rng, r * 0.16), r * 0.045, purple)
		"heinz":
			for i in range(mini(count, 3)):
				var a: float = rotation + i * 1.7
				ci.draw_circle(pos + Vector2.from_angle(a) * r * 0.78, r * 0.13, purple)
		"cabot":
			var loop := PackedVector2Array()
			for i in range(65):
				var a: float = TAU * i / 64.0
				loop.append(_at(Vector2(sin(a) * r * 0.48, sin(2.0 * a) * r * 0.26), pos, rotation))
			ci.draw_polyline(loop, purple, maxf(1.0, r * 0.035), true)
		"ring_form":
			for i in range(count):
				var center: Vector2 = pos + _random_point(rng, r * 0.55)
				ci.draw_arc(center, r * 0.18, 0.0, TAU, 24, blue, maxf(1.0, r * 0.035), true)
				ci.draw_circle(center + Vector2(r * 0.13, -r * 0.13), r * 0.055, Color("#B32E64"))
		"babesia_tetrad":
			for i in range(4):
				var a: float = rotation + PI * 0.5 * i
				var center: Vector2 = pos + Vector2.from_angle(a) * r * 0.18
				_polygon(ci, CellShapes.teardrop(r * 0.15), center, a + PI * 0.5, blue)
				ci.draw_circle(center, r * 0.04, Color("#B32E64"))
		"reticulum":
			for i in range(5):
				var strand := PackedVector2Array()
				for j in range(5):
					strand.append(pos + _random_point(rng, r * 0.75))
				ci.draw_polyline(strand, blue, maxf(1.0, r * 0.035), true)


static func _draw_wbc(ci: CanvasItem, desc: Dictionary, pos: Vector2, r: float, rotation: float, rng: RandomNumberGenerator) -> void:
	var color: Color = _color(desc.get("cytoplasm"), Color("#E8D4E0"))
	var features: Array = _array(desc.get("features"))
	if features.has("smudge"):
		_polygon(ci, CellShapes.spiculated(r * 0.75, 12, r * 0.25, true, rng), pos, rotation, Color("#B8A0C4"))
	else:
		_disc(ci, pos, r, color)
	if features.has("hairy_projections"):
		for i in range(36):
			var a: float = TAU * i / 36.0 + rng.randf_range(-0.04, 0.04)
			ci.draw_line(pos + Vector2.from_angle(a) * r * 0.95, pos + Vector2.from_angle(a + 0.04) * r * rng.randf_range(1.08, 1.22), color.darkened(0.16), 1.2, true)
	if features.has("skirt_basophilia"):
		ci.draw_arc(pos, r * 0.88, rotation, rotation + PI * 1.4, 40, Color("#7696C5"), r * 0.16, true)
	var granules: Dictionary = _dict(desc.get("granules"))
	if not bool(granules.get("over_nucleus", false)):
		_draw_granules(ci, granules, pos, r, rng)
	if features.has("perinuclear_halo"):
		ci.draw_circle(_at(Vector2(r * 0.18, 0), pos, rotation), r * 0.29, Color("#FAF2EF"))
	var nucleus: Dictionary = _dict(desc.get("nucleus"))
	if nucleus.is_empty():
		nucleus = {"shape": "round", "nc": 0.6}
	_draw_nucleus(ci, nucleus, pos, r, rotation, rng)
	if bool(granules.get("over_nucleus", false)):
		_draw_granules(ci, granules, pos, r, rng)
	if features.has("smudge"):
		for i in range(14):
			var p: Vector2 = pos + _random_point(rng, r * 0.7)
			ci.draw_line(p, p + Vector2(r * rng.randf_range(0.12, 0.5), r * 0.15).rotated(rotation), Color("#73558C"), 1.5, true)
	if features.has("auer_rod"):
		var start: Vector2 = _at(Vector2(r * 0.3, r * 0.45), pos, rotation)
		ci.draw_line(start, start + Vector2(r * 0.4, -r * 0.18).rotated(rotation), Color("#C54D75"), maxf(2.0, r * 0.06), true)
	if features.has("vacuoles"):
		for i in range(4):
			var p: Vector2 = pos + _random_point(rng, r * 0.8)
			_disc(ci, p, r * rng.randf_range(0.07, 0.12), Color("#FAF7F2"))
	if features.has("dohle"):
		_polygon(ci, CellShapes.ellipse(r * 0.17, r * 0.08), _at(Vector2(r * 0.67, 0), pos, rotation), rotation, Color("#9BAED1"), false)
	if features.has("toxic"):
		_draw_granules(ci, {"density": 0.8, "size": "coarse", "color": "#634671"}, pos, r, rng)


static func _draw_granules(ci: CanvasItem, desc: Dictionary, pos: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	if desc.is_empty():
		return
	var density: float = clampf(_number(desc.get("density"), 0.4), 0.0, 3.0)
	var count: int = mini(450, int(density * PI * r * r / 40.0))
	var color: Color = _color(desc.get("color"), Color("#C96AA0"))
	var granule_r: float = r * (0.045 if str(desc.get("size", "fine")) == "coarse" else 0.022)
	for i in range(count):
		ci.draw_circle(pos + _random_point(rng, r * 0.9), maxf(0.65, granule_r * rng.randf_range(0.8, 1.2)), color)


static func _draw_nucleus(ci: CanvasItem, desc: Dictionary, pos: Vector2, cell_r: float, rotation: float, rng: RandomNumberGenerator) -> void:
	var r: float = cell_r * clampf(_number(desc.get("nc"), 0.6), 0.15, 0.95)
	var shape: String = str(desc.get("shape", "round"))
	var color: Color = _color(desc.get("color"), Color("#5B3A7A"))
	var center: Vector2 = pos
	var points: PackedVector2Array
	match shape:
		"kidney": points = CellShapes.kidney(r)
		"band": points = CellShapes.band(r)
		"segmented", "bilobed": points = CellShapes.lobed_nucleus(r, int(_number(desc.get("lobes"), 2 if shape == "bilobed" else 3)), rng)
		"oval": points = CellShapes.ellipse(r * 0.82, r)
		"folded":
			points = CellShapes.kidney(r)
			center += Vector2(cell_r * 0.1, 0).rotated(rotation)
		"eccentric":
			points = CellShapes.circle(r * 0.85)
			center += Vector2(-cell_r * 0.24, 0).rotated(rotation)
		_: points = CellShapes.circle(r)
	_polygon(ci, points, center, rotation, color)
	var chromatin: String = str(desc.get("chromatin", "coarse"))
	var dot_r: float = r * (0.07 if chromatin == "clumped" else (0.035 if chromatin == "coarse" else 0.018))
	for i in range(45):
		var p: Vector2 = _random_point(rng, r * 0.95)
		if Geometry2D.is_point_in_polygon(p, points):
			ci.draw_circle(_at(p, center, rotation), maxf(0.5, dot_r), color.darkened(0.18))
	var nucleoli: int = clampi(int(_number(desc.get("nucleoli"), 0)), 0, 6)
	var placed: int = 0
	for i in range(60):
		if placed >= nucleoli:
			break
		var p: Vector2 = _random_point(rng, r * 0.65)
		if Geometry2D.is_point_in_polygon(p, points):
			ci.draw_circle(_at(p, center, rotation), r * 0.12, color.lightened(0.45))
			placed += 1


static func _draw_platelet(ci: CanvasItem, desc: Dictionary, pos: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var color: Color = _color(desc.get("color"), Color("#B29CC7"))
	_disc(ci, pos, r, color)
	var granules: Dictionary = _dict(desc.get("granules"))
	var granule_color: Color = _color(granules.get("color"), Color("#6F4889"))
	for i in range(7):
		ci.draw_circle(pos + _random_point(rng, r * 0.6), maxf(0.7, r * 0.12), granule_color)


static func _draw_field(ci: CanvasItem, desc: Dictionary, pos: Vector2, cell_scale_px: float, rng: RandomNumberGenerator) -> void:
	var arrangement: String = str(desc.get("arrangement", "rouleaux"))
	var rbc := {"kind": "rbc", "shape": "disc", "pallor": 0.33}
	match arrangement:
		"satellitism":
			var central: Dictionary = _dict(desc.get("cell"))
			if central.is_empty() or str(central.get("kind", "wbc")) == "field":
				central = {"kind": "wbc", "size": 1.6, "nucleus": {"shape": "segmented", "lobes": 3}}
			draw_cell(ci, central, pos, cell_scale_px, rng.randi())
			for i in range(12):
				var a: float = TAU * i / 12.0
				draw_cell(ci, {"kind": "platelet"}, pos + Vector2.from_angle(a) * cell_scale_px * 0.94, cell_scale_px, rng.randi())
		"platelet_clump":
			for i in range(4):
				draw_cell(ci, rbc, pos + Vector2.from_angle(TAU * i / 4.0) * cell_scale_px * 0.95, cell_scale_px * 0.8, rng.randi())
			for i in range(16):
				draw_cell(ci, {"kind": "platelet"}, pos + _random_point(rng, cell_scale_px * 0.48), cell_scale_px, rng.randi())
		"agglutinate":
			for i in range(10):
				draw_cell(ci, rbc, pos + _random_point(rng, cell_scale_px * 0.9), cell_scale_px * 0.8, rng.randi())
		_:
			for i in range(6):
				var offset := Vector2((i - 2.5) * cell_scale_px * 0.32, (i - 2.5) * cell_scale_px * 0.16)
				draw_cell(ci, rbc, pos + offset, cell_scale_px * 0.85, rng.randi())
