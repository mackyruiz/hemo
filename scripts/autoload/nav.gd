extends Node
## Screen router. Screens are scripts extending Control, built in code.

const ROUTES := {
	"hub": "res://scripts/screens/hub.gd",
	"lab_floor": "res://scripts/screens/lab_floor.gd",
	"practice": "res://scripts/screens/practice_picker.gd",
	"shift": "res://scripts/screens/shift_runner.gd",
	"shift_summary": "res://scripts/screens/shift_summary.gd",
	"exam": "res://scripts/screens/exam.gd",
	"exam_report": "res://scripts/screens/exam_report.gd",
	"progress": "res://scripts/screens/progress_screen.gd",
	"atlas": "res://scripts/screens/atlas.gd",
	"atlas_entry": "res://scripts/screens/atlas_entry.gd",
	"settings": "res://scripts/screens/settings.gd",
	"ranges": "res://scripts/screens/ranges.gd",
	"credits": "res://scripts/screens/credits.gd",
	"about": "res://scripts/screens/about.gd",
	"flagged": "res://scripts/screens/flagged.gd",
	"flagged_question": "res://scripts/screens/flagged_question.gd",
	"flashcards": "res://scripts/screens/flashcards.gd",
}

var _host: Control
var _current: Control
var _stack: Array[Dictionary] = []


func mount(host: Control) -> void:
	_host = host


func go(route: String, params: Dictionary = {}) -> void:
	_show(route, params)
	_stack.append({"route": route, "params": params})


func replace(route: String, params: Dictionary = {}) -> void:
	if not _stack.is_empty():
		_stack.pop_back()
	go(route, params)


func back() -> void:
	if _current != null and _current.has_method("can_leave"):
		# can_leave() may open a dialog and return false; the screen then calls
		# Nav.force_back() itself on confirmation.
		if not _current.can_leave():
			return
	force_back()


func force_back() -> void:
	if not _stack.is_empty():
		_stack.pop_back()
	if _stack.is_empty():
		go("hub")
		return
	var top: Dictionary = _stack[-1]
	_show(top.route, top.params)


func _show(route: String, params: Dictionary) -> void:
	assert(ROUTES.has(route), "Unknown route: " + route)
	var node: Control = load(ROUTES[route]).new()
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	if node.has_method("setup"):
		node.setup(params)
	if _current != null:
		_host.remove_child(_current)
		_current.queue_free()
	_current = node
	_host.add_child(node)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
