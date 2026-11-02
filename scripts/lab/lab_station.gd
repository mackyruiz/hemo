class_name LabStation
extends Control
## Base overlay for a Lab Floor instrument station.
##
## Stations are sandbox activities: they never call Progress, Nav or any other
## autoload that could write save state. A subclass overrides `_start()` and
## rebuilds its body through `clear_body()`.
##
## Every activity runs explicit phases (setup / animating / answer / feedback),
## rejects out-of-phase input and commits each submission exactly once. Tween
## callbacks are preferred over `await` so that closing the overlay frees
## everything cleanly.

signal closed

## Shared, mutable session state owned by the Lab Floor screen. Stored by
## reference so stations can hand findings to each other (e.g. analyzer -> scope).
var session: Dictionary
## Scrollable body column. Index 0 is always the "back to lab floor" button.
var content: VBoxContainer
var rng := RandomNumberGenerator.new()


func open(s: Dictionary, title: String) -> void:
	session = s
	rng.randomize()
	var page: Array = UI.page(title, false)
	add_child(page[0])
	content = page[1]
	var back: Button = UI.button("‹ Back to lab floor", func(): closed.emit(), "SecondaryButton")
	back.focus_mode = Control.FOCUS_NONE
	content.add_child(back)
	_start()


## Subclass hook: build the first phase of the activity.
func _start() -> void:
	pass


## Removes every body node except the back button.
func clear_body() -> void:
	var children: Array[Node] = content.get_children()
	for i in range(1, children.size()):
		var child: Node = children[i]
		content.remove_child(child)
		_child_cleanup(child)
		child.queue_free()


## Kills tweens owned by a subtree before it is freed, so no callback can fire
## against a detached node.
func _child_cleanup(node: Node) -> void:
	if node is CanvasItem and node.has_meta("station_tween"):
		var tween: Tween = node.get_meta("station_tween") as Tween
		if tween != null and tween.is_valid():
			tween.kill()
		node.remove_meta("station_tween")
	for child in node.get_children():
		_child_cleanup(child)


## Starts a tween owned by `node` and records it so cleanup can kill it.
func track_tween(node: Node, tween: Tween) -> Tween:
	node.set_meta("station_tween", tween)
	return tween


## A labelled slider row in a fixed-height holder.
func slider_row(label_text: String, minimum: float, maximum: float, step: float) -> Array:
	var v: VBoxContainer = UI.vbox(4)
	v.add_child(UI.label(label_text))
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.custom_minimum_size.y = 48
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	v.add_child(slider)
	content.add_child(v)
	return [v, slider]


## Standard station question: feedback on, station RNG, no hint elimination.
func ask(question: Dictionary) -> QuestionPanel:
	var panel := QuestionPanel.new()
	content.add_child(panel)
	panel.setup(question, {"show_feedback": true, "rng": rng, "allow_hint": false})
	return panel
