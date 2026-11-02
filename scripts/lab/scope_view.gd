class_name ScopeView
extends Control
## Magnified microscope field of the smear strip.
##
## The parent paints the #FFF9F3 circular background once; three full-rect cell
## layers stack on top (the base layer plus two defocus ghosts) and a mask
## child hides everything outside the circle, draws the rim and the target
## pointer. Cells are redrawn only through `refresh()` on state changes, so
## there is no per-frame microscope animation loop.

const BACKGROUND := Color("#FFF9F3")
const RIM := Color("#2E2A33")
const POINTER_WIDTH := 4.0
const TARGET_GAP := 6.0
const BLUR_OFFSET := Vector2(0.35, 0.2)
const RBC_ART := {"kind": "rbc", "shape": "disc", "pallor": 0.33, "color": "#D98C8C"}
const EDGE_ART := {"kind": "rbc", "shape": "disc", "pallor": 0.0, "color": "#D98C8C"}
const PALE_BLUE_ART := {"kind": "rbc", "shape": "disc", "pallor": 0.33, "color": "#C3DBE8"}
const GHOST_ART := {"kind": "rbc", "shape": "disc", "pallor": 0.0, "color": "#EFE6E8"}

var logic: ScopeLogic
var cells: Array[Dictionary] = []
var target_art: Dictionary = {}
var pointer_index: int = -1

var _layers: Array[_ScopeChild] = []
var _mask: _ScopeChild
var _radius: float = 8.0
var _px_per_unit: float = 1.0


class _ScopeChild extends Control:
	var view: ScopeView
	var layer: int = 0
	var offset := Vector2.ZERO

	func _init(v: ScopeView, l: int) -> void:
		view = v
		layer = l
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		view._draw_child(self, layer, offset)


func _init() -> void:
	custom_minimum_size = Vector2(0, 560)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	for i in range(3):
		var layer := _ScopeChild.new(self, i)
		add_child(layer)
		_layers.append(layer)
	_mask = _ScopeChild.new(self, -1)
	add_child(_mask)
	resized.connect(refresh)
	refresh()


## Updates the ghost offsets/alphas and redraws every layer. Call only on
## stage / objective / focus / slide / size changes.
func refresh() -> void:
	if logic == null:
		return
	_recalc()
	var blur := logic.blur()
	for layer in _layers:
		if layer.layer == 0:
			layer.offset = Vector2.ZERO
			layer.modulate.a = 1.0 - 0.5 * blur
			layer.visible = true
		elif layer.layer == 1:
			layer.offset = BLUR_OFFSET * blur * _px_per_unit
			layer.modulate.a = 0.25 * blur
			layer.visible = blur > 0.0
		else:
			layer.offset = -BLUR_OFFSET * blur * _px_per_unit
			layer.modulate.a = 0.25 * blur
			layer.visible = blur > 0.0
		layer.queue_redraw()
	if _mask != null:
		_mask.queue_redraw()
	queue_redraw()


func _recalc() -> void:
	_radius = maxf(1.0, minf(size.x, size.y) * 0.5 - 8.0)
	var view_radius := 8.0
	if logic != null:
		view_radius = float(ScopeLogic.VIEW_RADIUS[logic.objective])
	_px_per_unit = _radius / view_radius


func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	draw_circle(size * 0.5, _radius, BACKGROUND)


func _draw_child(child: CanvasItem, layer: int, offset: Vector2) -> void:
	if logic == null:
		return
	if layer < 0:
		_draw_mask(child)
	else:
		_draw_cells(child, offset)


func _draw_cells(ci: CanvasItem, offset: Vector2) -> void:
	var center := size * 0.5
	var view_center := Vector2(logic.stage_x, ScopeLogic.VIEW_Y)
	var limit := float(ScopeLogic.VIEW_RADIUS[logic.objective]) + 2.0
	for cell in cells:
		var pos: Vector2 = cell["pos"]
		if pos.distance_to(view_center) > limit:
			continue
		var art := _art_for(str(cell["kind"]))
		if art.is_empty():
			continue
		var screen_pos := (pos - view_center) * _px_per_unit + center + offset
		CellArt.draw_cell(ci, art, screen_pos, _px_per_unit, int(cell["seed"]))


## Prep-specific background art: pale blue RBCs for supravital stains, pale
## adult-cell ghosts for acid elution. Never an ordinary Wright–Giemsa finding.
func _art_for(kind: String) -> Dictionary:
	if kind == "target":
		return target_art
	if kind == "plt":
		var platelet: Dictionary = Content.morph.get("normal_platelet", {})
		var platelet_art: Variant = platelet.get("art", {})
		return platelet_art if platelet_art is Dictionary else {}
	var background := _prep_background()
	if not background.is_empty():
		return background
	return EDGE_ART if kind == "edge" else RBC_ART


func _prep_background() -> Dictionary:
	if logic == null:
		return {}
	match logic.prep:
		"retic", "heinz":
			return PALE_BLUE_ART
		"kb":
			return GHOST_ART
		_:
			return {}


func _draw_mask(ci: CanvasItem) -> void:
	var center := size * 0.5
	var thickness := 2.0 * size.length()
	ci.draw_arc(center, _radius + thickness * 0.5, 0.0, TAU, 96, Color.BLACK, thickness)
	ci.draw_arc(center, _radius, 0.0, TAU, 96, RIM, 2.0)
	_draw_pointer(ci)


## A 4px line from the circle's left edge to just short of the target.
func _draw_pointer(ci: CanvasItem) -> void:
	if logic == null or pointer_index < 0 or pointer_index >= cells.size():
		return
	var pos: Vector2 = cells[pointer_index]["pos"]
	var view_center := Vector2(logic.stage_x, ScopeLogic.VIEW_Y)
	var target := (pos - view_center) * _px_per_unit + size * 0.5
	var left := size.x * 0.5 - _radius
	if target.x <= left + TARGET_GAP:
		return
	ci.draw_line(Vector2(left, target.y), Vector2(target.x - TARGET_GAP, target.y), ThemeBuilder.ACCENT, POINTER_WIDTH, true)
