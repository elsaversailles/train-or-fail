extends Node
signal timeline_ended
var started: Array[String] = []
func start(timeline: String) -> void:
	started.append(timeline)
