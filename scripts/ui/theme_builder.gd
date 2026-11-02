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


static func _box(bg: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0, margin: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.set_content_margin_all(margin)
	return sb


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
