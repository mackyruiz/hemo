class_name LabSprites
extends RefCounted
## Sprite sheet coordinates and generated 16x16 device art for the Lab Floor.
##
## Sheet tile geometry differs between packs: the two roguelike sheets use 16 px
## tiles with 1 px spacing (step 17), while the urban sheet is packed (step 16).


const INDOOR := "res://assets/lab/roguelike_indoor.png"
const CITY := "res://assets/lab/roguelike_city.png"
const URBAN := "res://assets/lab/rpg_urban.png"

## Map character -> [sheet, column, row].
const TILES := {
	"W": [CITY, 9, 5],  # beige brick wall
	".": [CITY, 17, 3],  # framed gray floor
	"a": [INDOOR, 0, 13],  # cabinet counter
	"s": [INDOOR, 8, 13],  # sink counter
	"r": [INDOOR, 5, 13],  # reagent-bottle counter
	"b": [INDOOR, 6, 13],  # second bottle counter
	"p": [INDOOR, 16, 0],  # potted plant (transparent background)
	"D": [URBAN, 15, 10],  # glass double door
}

## Counter tile drawn under every device sprite.
const COUNTER := [INDOOR, 0, 13]

const DIR_DOWN := 0
const DIR_LEFT := 1
const DIR_RIGHT := 2
const DIR_UP := 3

## Player sprite column per facing direction (urban sheet, green-shirt character).
const PLAYER_COLUMN := {0: 24, 1: 23, 2: 26, 3: 25}

## Row 0 is idle; rows 1 and 2 are the walk frames.
const WALK_ROWS := [1, 0, 2, 0]

## Color keys used by the ASCII device art.
const PALETTE := {
	"K": "#2E2A33",
	"W": "#F4F4F2",
	"L": "#C9CCD3",
	"G": "#8A8F99",
	"D": "#4F535C",
	"C": "#7FD6E6",
	"B": "#3E6FB8",
	"R": "#B3263E",
	"P": "#9B7FD1",
	"S": "#6FB7E9",
	"Y": "#F2D16B",
	"g": "#3FAE5A",
}

## Original 16x16 device art, one row of 16 characters per entry. `.` is transparent.
const DEVICE_ART := {
	"microscope": [
		"................",
		"......KKK.......",
		".....KLLLK......",
		".....KDGDK......",
		"......KGK.......",
		".....KGLGKKK....",
		".....KGLLKDGK...",
		"....KGGLKKLGK...",
		"...KDDDDDKLGK...",
		"...KLLLLLKLGK...",
		"....KKGKK.KLGK..",
		"......KGKKKLGK..",
		"...KKKKKKKKKKKK.",
		"..KLLLLLLLLLLLLK",
		"..KGGGGGGGGGGGGK",
		"...KKKKKKKKKKKK.",
	],
	"centrifuge": [
		"................",
		"..KKKKKKKKKKKK..",
		".KLLLLLLLLLLLLK.",
		".KLKKKKKKKKKKLK.",
		".KLKDDDDDDDDKLK.",
		".KLKDGGLLGGDKLK.",
		".KLKDGRWWRGDKLK.",
		".KLKDLWDDWLDKLK.",
		".KLKDLWDDWLDKLK.",
		".KLKDGRWWRGDKLK.",
		".KLKDGGLLGGDKLK.",
		".KLKDDDDDDDDKLK.",
		".KLKKKKKKKKKKLK.",
		".KLLLLKCCKLLgLK.",
		".KGGGGKKKKGGGGK.",
		"..KKKKKKKKKKKK..",
	],
	"analyzer": [
		"................",
		".KKKKKKKKKKKKKK.",
		".KWWWWWWWWWWWWK.",
		".KWKKKKKKWWWWWK.",
		".KWKCCCCKWWgWWK.",
		".KWKCBBCKWWWWWK.",
		".KWKCCCCKWLLLWK.",
		".KWKKKKKKWKPKWK.",
		".KWWWWWWWWKRKWK.",
		".KLLLLLLLLKRKLK.",
		".KLGGGGGGLKKKLK.",
		".KLLLLLLLLLLLLK.",
		".KGGGGGGGGGGGGK.",
		".KLLLLLLLLLLLLK.",
		".KGGGGGGGGGGGGK.",
		".KKKKKKKKKKKKKK.",
	],
	"tube_rack": [
		"................",
		"................",
		"..KK.KK.KK.KK...",
		"..PP.SS.PP.YY...",
		"..KK.KK.KK.KK...",
		"..WR.WY.WR.WR...",
		"..WR.WY.WR.WR...",
		"..RR.RY.RR.RR...",
		"KKRRKRRKRRKRRKKK",
		"KLLLLLLLLLLLLLLK",
		"KGGGGGGGGGGGGGGK",
		"KLLLLLLLLLLLLLLK",
		"KKKKKKKKKKKKKKKK",
		"................",
		"................",
		"................",
	],
	"esr_rack": [
		"................",
		".KKKKKKKKKKKKKK.",
		".KLLLLLLLLLLLLK.",
		".KL.KW.KW.KW.LK.",
		".KL.KY.KY.KY.LK.",
		".KL.KY.KY.KY.LK.",
		".KL.KY.KR.KY.LK.",
		".KL.KR.KR.KY.LK.",
		".KL.KR.KR.KR.LK.",
		".KL.KR.KR.KR.LK.",
		".KL.KR.KR.KR.LK.",
		".KL.KR.KR.KR.LK.",
		".KL.KR.KR.KR.LK.",
		".KLLLLLLLLLLLLK.",
		".KGGGGGGGGGGGGK.",
		".KKKKKKKKKKKKKK.",
	],
	"terminal": [
		"................",
		"..KKKKKKKKKKKK..",
		"..KDDDDDDDDDDK..",
		"..KDCCCCCCCCDK..",
		"..KDCBBBBBCCDK..",
		"..KDCCCCCCCCDK..",
		"..KDCBBBCCCCDK..",
		"..KDCCCCCCCCDK..",
		"..KDDDDDDDDDDK..",
		"..KKKKKDDKKKKK..",
		"......KDDK......",
		"....KKKKKKKK....",
		"..KKLLLLLLLLKK..",
		".KLKLKLKLKLKLLK.",
		".KGGGGGGGGGGGGK.",
		"..KKKKKKKKKKKK..",
	],
}

static var _cache: Dictionary = {}


## Sheet region of one 16x16 tile. Step is 16 for the packed urban sheet, 17 otherwise.
static func region(col: int, row: int, sheet: String) -> Rect2:
	var step := 16 if sheet == URBAN else 17
	return Rect2(col * step, row * step, 16, 16)


## Sheet region of one player frame.
static func player_region(dir: int, row: int) -> Rect2:
	var column: int = PLAYER_COLUMN[dir]
	return Rect2(column * 16, row * 16, 16, 16)


## Texture for one generated device sprite, built once and cached per id.
static func device_texture(id: String) -> ImageTexture:
	assert(DEVICE_ART.has(id), "Unknown device sprite id: %s" % id)
	if _cache.has(id):
		var cached: ImageTexture = _cache[id]
		return cached
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var rows: Array = DEVICE_ART[id]
	for y in 16:
		var line: String = rows[y]
		for x in 16:
			var key := line[x]
			if key == ".":
				continue
			var hex: String = PALETTE[key]
			img.set_pixel(x, y, Color(hex))
	var texture := ImageTexture.create_from_image(img)
	_cache[id] = texture
	return texture
