extends Control


func _ready() -> void:
	Nav.mount(self)
	Nav.go("hub")
