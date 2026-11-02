class_name LabView
extends Control
## Draws the Lab Floor map and the walking player.
##
## The whole floor is one CanvasItem redraw: 11x13 tiles at the largest
## multiple of 16 px that fits, centered, with the player sprite on top.

var player_pos := LabMap.SPAWN
var facing := LabSprites.DIR_UP
var walk_row := 0
## Station id whose cell is outlined as "in reach", or "".
var highlight := ""
var pulse := 0.0

var _sheets: Dictionary = {}
var _stations: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sheet: String in [LabSprites.INDOOR, LabSprites.CITY, LabSprites.URBAN]:
		_sheets[sheet] = load(sheet) as Texture2D
	_stations = LabMap.station_cells()
	resized.connect(queue_redraw)


func _draw() -> void:
	var grid: Vector2i = LabMap.grid_size()
	var fit: float = minf(size.x / float(grid.x), size.y / float(grid.y))
	var tile: float = fit if fit < 16.0 else floorf(fit / 16.0) * 16.0
	var origin: Vector2 = (size - Vector2(grid) * tile) * 0.5
	var floor_entry: Array = LabSprites.TILES["."]
	for y in range(grid.y):
		for x in range(grid.x):
			var code: String = LabMap.cell(x, y)
			var dest := Rect2(origin + Vector2(x, y) * tile, Vector2.ONE * tile)
			_draw_tile(floor_entry, dest)
			if LabSprites.TILES.has(code) and code != ".":
				_draw_tile(LabSprites.TILES[code], dest)
			elif LabMap.DEVICE_SPRITE.has(code):
				_draw_tile(LabSprites.COUNTER, dest)
				draw_texture_rect(LabSprites.device_texture(LabMap.DEVICE_SPRITE[code]), dest, false)
	var player_dest := Rect2(origin + (player_pos - Vector2(0.5, 0.9)) * tile, Vector2.ONE * tile)
	draw_texture_rect_region(_sheets[LabSprites.URBAN] as Texture2D, player_dest, LabSprites.player_region(facing, walk_row))
	if highlight != "":
		var cell_index: Vector2i = _stations.get(highlight, Vector2i(-1, -1))
		if cell_index.x >= 0:
			var outline := Rect2(origin + Vector2(cell_index) * tile, Vector2.ONE * tile).grow(-1.5)
			draw_rect(outline, Color(ThemeBuilder.ACCENT, 0.5 + 0.5 * sin(pulse * 6.0)), false, 3.0)


func _draw_tile(entry: Array, dest: Rect2) -> void:
	var texture: Texture2D = _sheets[entry[0]] as Texture2D
	if texture == null:
		return
	draw_texture_rect_region(texture, dest, LabSprites.region(int(entry[1]), int(entry[2]), str(entry[0])))
