extends Control

var _large_text: CheckButton
var _reset_dialog: ConfirmationDialog


func _ready() -> void:
	var page: Array = UI.page("Settings")
	add_child(page[0])
	var content: VBoxContainer = page[1]
	var settings: Dictionary = Progress.data.get("settings", {})
	_large_text = CheckButton.new()
	_large_text.custom_minimum_size.y = 64
	_large_text.button_pressed = bool(settings.get("large_text", false))
	_sync_toggle_text()
	_large_text.toggled.connect(func(value: bool):
		_sync_toggle_text()
		Progress.set_setting("large_text", value)
	)
	content.add_child(_large_text)
	content.add_child(UI.button("Reference ranges used in this app", func(): Nav.go("ranges"), "SecondaryButton"))
	content.add_child(UI.button("Reset progress", _confirm_reset, "SecondaryButton"))
	content.add_child(UI.label("Reset removes your XP, review history, mock exams, and settings from this device.", "MutedLabel"))
	content.add_child(UI.button("Credits & licenses", func(): Nav.go("credits"), "SecondaryButton"))
	content.add_child(UI.button("About", func(): Nav.go("about"), "SecondaryButton"))
	_reset_dialog = UI.confirm_dialog("Reset progress?", "All progress and settings on this device will be reset. This cannot be undone.", "Reset progress")
	_reset_dialog.confirmed.connect(_reset)
	add_child(_reset_dialog)


func _confirm_reset() -> void:
	UI.popup_confirm(_reset_dialog)


func _reset() -> void:
	Progress.reset()
	_large_text.set_pressed_no_signal(false)
	_sync_toggle_text()
	UI.toast(self, "Progress has been reset.")


## The switch icon alone is low-contrast on the light theme; state is also spelled out.
func _sync_toggle_text() -> void:
	_large_text.text = "Large text: On" if _large_text.button_pressed else "Large text: Off"
