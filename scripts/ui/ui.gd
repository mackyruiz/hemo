class_name UI
extends RefCounted
## Static helpers returning configured UI nodes.

## Pointer travel that counts as a scroll drag rather than a tap on a control.
const DRAG_DEADZONE := 12.0


## Returns [root_control, content_vbox]. Top bar has Back + title; content scrolls
## inside a centered, max-width column.
static func page(title: String, show_back: bool = true) -> Array:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	root.add_child(outer)

	var bar_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		bar_margin.add_theme_constant_override("margin_" + side, 8)
	outer.add_child(bar_margin)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar_margin.add_child(bar)
	if show_back:
		var back := button("‹ Back", func(): Nav.back(), "SecondaryButton")
		back.custom_minimum_size.x = 120
		bar.add_child(back)
	var t := label(title, "TitleLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(t)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 24)
	var fit := func():
		var m: int = int(max(16.0, (scroll.size.x - 760.0) / 2.0))
		margin.add_theme_constant_override("margin_left", m)
		margin.add_theme_constant_override("margin_right", m)
	scroll.resized.connect(fit)
	fit.call_deferred()

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	return [root, content]


static func label(text: String, variation: String = "") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if variation != "":
		l.theme_type_variation = variation
	return l


static func button(text: String, callback: Callable, variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	# Autowrapped buttons report ~0 minimum width; keep them tappable inside rows.
	b.custom_minimum_size = Vector2(120, 64)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if variation != "":
		b.theme_type_variation = variation
	# A press that stops at the button never reaches the scroll container, so a drag that
	# starts here would not scroll; pass events up and count only a release near the press
	# point as a tap.
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	# Lambdas capture locals by value, so the guard state has to be one shared object.
	var tap: Dictionary = {"travel": 0.0}
	b.gui_input.connect(func(event: InputEvent) -> void:
		var key: String = _pointer_key(event)
		if key == "":
			return
		var at: Vector2 = _pointer_position(b, event)
		if event.pressed:
			tap[key] = at
			tap["travel"] = 0.0
		else:
			tap["travel"] = at.distance_to(tap.get(key, at))
	)
	b.pressed.connect(func() -> void:
		if tap["travel"] > DRAG_DEADZONE:
			return
		callback.call()
	)
	return b


## Tap handler for a card: ignores releases past the drag deadzone so scrolling over the
## card does not fire it.
static func tappable(control: Control, callback: Callable) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	# Lambdas capture locals by value, so the guard state has to be one shared object.
	var tap: Dictionary = {}
	control.gui_input.connect(func(event: InputEvent) -> void:
		var key: String = _pointer_key(event)
		if key == "":
			return
		var at: Vector2 = _pointer_position(control, event)
		if event.pressed:
			tap[key] = at
			return
		var travel: float = at.distance_to(tap.get(key, at))
		if travel <= DRAG_DEADZONE:
			callback.call()
	)


## Which pointer family an event belongs to; "" for events the tap guard ignores.
static func _pointer_key(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		return "mouse" if event.button_index == MOUSE_BUTTON_LEFT else ""
	if event is InputEventScreenTouch:
		return "screen"
	return ""


## Screen-touch events carry no global position in the web build, so rebuild it from the
## control origin plus the position relative to that control.
static func _pointer_position(control: Control, event: InputEvent) -> Vector2:
	var global: Variant = event.get("global_position")
	if global is Vector2:
		return global
	return control.get_global_position() + event.position


## "Read more" button for a source id; null if the id is unknown.
static func source_link(source_id: String) -> Button:
	var s: Dictionary = Content.sources.get(source_id, {})
	if s.is_empty():
		return null
	var url: String = str(s["url"])
	return button("Read more ↗  %s (%s)" % [s["title"], s["publisher"]], func(): OS.shell_open(url), "SecondaryButton")


static func card() -> PanelContainer:
	var c := PanelContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Stop-filtered cards eat the press, so a drag starting on them never scrolls; pair
	# with UI.tappable for card taps.
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


## Bottom label that fades out after 2.5 s.
static func toast(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_stylebox_override("normal", ThemeBuilder._box(Color(0.13, 0.13, 0.13, 0.92), 12, Color(0, 0, 0, 0), 0, 14))
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_left = 24
	l.offset_right = -24
	l.offset_top = -140
	l.offset_bottom = -40
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


## Themed ConfirmationDialog with wrapping text; show via popup_confirm().
static func confirm_dialog(title: String, text: String, ok_text: String, cancel_text: String = "Cancel") -> ConfirmationDialog:
	var d := ConfirmationDialog.new()
	d.title = title
	d.dialog_text = text
	d.dialog_autowrap = true
	d.ok_button_text = ok_text
	d.cancel_button_text = cancel_text
	return d


static func popup_confirm(d: ConfirmationDialog) -> void:
	var host: Control = d.get_parent() as Control
	var width: int = int(minf(600.0, host.get_viewport_rect().size.x - 64.0)) if host != null else 600
	d.popup_centered(Vector2i(width, 0))
