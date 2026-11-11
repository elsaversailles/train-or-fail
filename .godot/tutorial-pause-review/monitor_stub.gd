extends Node
var idle_calls: int = 0
func set_idle_visible(_visible: bool) -> void:
	idle_calls += 1

