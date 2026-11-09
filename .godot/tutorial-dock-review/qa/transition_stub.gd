extends Node
signal transition_finished
var is_transitioning := false
var destination := ""
func change_scene(path: String) -> void:
	destination = path
