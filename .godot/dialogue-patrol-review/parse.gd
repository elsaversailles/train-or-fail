extends Node

func _ready() -> void:
	var failed := false
	for script_name in ["Grandpa", "Mark", "NurseClara", "jericho", "PartnerNPC"]:
		var script = load("res://scripts/dialogue/%s.gd" % script_name)
		if not script or not script.can_instantiate():
			failed = true
			push_error("Cannot compile dialogue script: " + script_name)
	print("DIALOGUE_PATROL_COMPILE failed=", failed)
	get_tree().quit(1 if failed else 0)
