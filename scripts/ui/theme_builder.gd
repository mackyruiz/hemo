class_name ThemeBuilder
extends RefCounted
## Builds the app-wide Theme in code.

const BG := Color("#F7F4F2")
const SURFACE := Color("#FFFFFF")
const PRIMARY := Color("#B3263E")
const ACCENT := Color("#4A5BA8")
const SUCCESS := Color("#2E8B57")
const ERROR := Color("#C0392B")
const TEXT := Color("#222222")
const MUTED := Color("#6B6B6B")
# Pastel study-tool colors keep Hint and Flag visually apart from the white answer choices.
const HINT_BG := Color("#FFF3C4")
const HINT_FG := Color("#6B4E00")
const HINT_BORDER := Color("#E3C25A")
const FLAG_BG := Color("#E3E8FF")
const FLAG_FG := Color("#33428A")
const FLAG_BORDER := Color("#A9B5EA")
# Sort containers are told apart by tint and by glyph, so colour is never the only cue.
const SORT_TINTS := [
	Color("#B3263E"), Color("#4A5BA8"), Color("#9A6B00"),
	Color("#0F6F7A"), Color("#7A3E9D"), Color("#52606D"),
]
const SORT_GLYPHS := ["●", "▲", "■", "◆", "★", "✚"]
const CHIP_BORDER := Color("#BDB6B0")
const SUCCESS_BG := Color("#E8F5EE")
const ERROR_BG := Color("#FBEAE8")


static func _box(bg: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0, margin: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.set_content_margin_all(margin)
	return sb


static func sort_tint(index: int) -> Color:
	return SORT_TINTS[index % SORT_TINTS.size()]


static func sort_glyph(index: int) -> String:
	return SORT_GLYPHS[index % SORT_GLYPHS.size()]


## Sort-chip icon box and the text indent that clears it, both derived from the font
## size so the large-text setting scales the art with the label.
const ICON_RATIO := 1.6
const ICON_GAP := 10

static func icon_px(font_size: int) -> int:
	return int(round(font_size * ICON_RATIO))


static func icon_text_pad(font_size: int) -> int:
	return 12 + icon_px(font_size) + ICON_GAP


## Per-node button colours. The disabled state keeps the same colours so results stay
## readable after the sort is checked.
static func tint_button(button: Button, bg: Color, fg: Color, border: Color, border_w: int, pad_left: int = 12) -> void:
	var fills := {"normal": bg, "hover": bg.lightened(0.06), "pressed": bg.darkened(0.08), "hover_pressed": bg.darkened(0.08), "disabled": bg}
	for state: String in fills:
		var sb := _box(fills[state], 12, border, border_w, 12)
		sb.content_margin_left = pad_left
		button.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(c, fg)


## Drops tint_button overrides so the button falls back to its theme variation.
static func clear_button_tint(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		button.remove_theme_stylebox_override(state)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.remove_theme_color_override(c)


static func _button_styles(theme: Theme, type_name: String, bg: Color, fg: Color, border: Color, border_w: int) -> void:
	var normal := _box(bg, 12, border, border_w, 12)
	var hover := _box(bg.lightened(0.08), 12, border, border_w, 12)
	var pressed := _box(bg.darkened(0.12), 12, border, border_w, 12)
	var disabled := _box(bg.lerp(Color("#CFCFCF"), 0.6), 12, border.lerp(Color("#CFCFCF"), 0.6), border_w, 12)
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("hover_pressed", type_name, pressed)
	theme.set_stylebox("disabled", type_name, disabled)
	theme.set_stylebox("focus", type_name, _box(Color(0, 0, 0, 0), 12, ACCENT, 3, 12))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(c, type_name, fg)
	theme.set_color("font_disabled_color", type_name, fg.lerp(Color("#999999"), 0.5))


static func build(large_text: bool) -> Theme:
	var theme := Theme.new()
	var fs := 30 if large_text else 24
	theme.default_font_size = fs
	theme.default_font = load("res://assets/fonts/DejaVuSans.ttf") as Font

	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", fs)

	theme.add_type("TitleLabel")
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", 42 if large_text else 34)
	theme.set_color("font_color", "TitleLabel", PRIMARY)

	theme.add_type("MutedLabel")
	theme.set_type_variation("MutedLabel", "Label")
	theme.set_color("font_color", "MutedLabel", MUTED)
	theme.set_font_size("font_size", "MutedLabel", fs - 4)

	theme.set_font_size("font_size", "Button", fs)
	theme.set_constant("h_separation", "Button", 8)
	_button_styles(theme, "Button", PRIMARY, Color.WHITE, Color(0, 0, 0, 0), 0)
	theme.set_stylebox("normal", "Button", _box(PRIMARY, 12, Color(0, 0, 0, 0), 0, 12))

	theme.add_type("SecondaryButton")
	theme.set_type_variation("SecondaryButton", "Button")
	_button_styles(theme, "SecondaryButton", SURFACE, PRIMARY, PRIMARY, 2)

	# Sortable items are neutral tags, visually unlike the red SecondaryButton actions and
	# unlike the tinted container targets.
	theme.add_type("ChipButton")
	theme.set_type_variation("ChipButton", "Button")
	_button_styles(theme, "ChipButton", SURFACE, TEXT, CHIP_BORDER, 2)

	theme.add_type("BinButton")
	theme.set_type_variation("BinButton", "Button")
	theme.set_font_size("font_size", "BinButton", fs - 6)

	for tool: Array in [["HintButton", HINT_BG, HINT_FG, HINT_BORDER], ["FlagButton", FLAG_BG, FLAG_FG, FLAG_BORDER]]:
		theme.add_type(tool[0])
		theme.set_type_variation(tool[0], "Button")
		_button_styles(theme, tool[0], tool[1], tool[2], tool[3], 2)
		theme.set_font_size("font_size", tool[0], fs - 4)

	theme.set_stylebox("panel", "PanelContainer", _box(SURFACE, 14, Color("#E6E1DD"), 1, 16))

	theme.set_font_size("font_size", "CheckButton", fs)
	# CheckButton inherits Button styles otherwise (red fill, unreadable dark text).
	var check_box := _box(SURFACE, 12, Color("#E6E1DD"), 1, 12)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, "CheckButton", check_box)
	theme.set_stylebox("focus", "CheckButton", _box(Color(0, 0, 0, 0), 12, ACCENT, 3, 12))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(c, "CheckButton", TEXT)
	theme.set_font_size("font_size", "LineEdit", fs)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_stylebox("normal", "LineEdit", _box(SURFACE, 10, Color("#BDB6B0"), 1, 12))
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), 10, ACCENT, 2, 12))

	theme.set_font_size("font_size", "OptionButton", fs)
	theme.set_font_size("normal_font_size", "RichTextLabel", fs)
	theme.set_color("default_color", "RichTextLabel", TEXT)

	var bar_bg := _box(Color("#E6E1DD"), 8)
	var bar_fill := _box(SUCCESS, 8)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	theme.set_font_size("font_size", "ProgressBar", fs - 6)
	theme.set_color("font_color", "ProgressBar", TEXT)

	# Embedded dialogs (ConfirmationDialog) must match the light app palette.
	var window_border := _box(SURFACE, 14, PRIMARY, 2, 0)
	window_border.set_expand_margin_all(8)
	window_border.expand_margin_top = 52
	theme.set_stylebox("embedded_border", "Window", window_border)
	theme.set_stylebox("embedded_unfocused_border", "Window", window_border)
	theme.set_color("title_color", "Window", PRIMARY)
	theme.set_font_size("title_font_size", "Window", fs)
	theme.set_constant("title_height", "Window", 48)
	theme.set_stylebox("panel", "AcceptDialog", _box(SURFACE, 0, Color(0, 0, 0, 0), 0, 16))
	theme.set_constant("buttons_separation", "AcceptDialog", 16)
	theme.set_constant("buttons_min_height", "AcceptDialog", 64)
	theme.set_constant("buttons_min_width", "AcceptDialog", 160)
	return theme
