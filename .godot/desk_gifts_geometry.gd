extends "res://.godot/desk_gifts_check.gd"

func _run() -> void:
	var scene := await load_department(DEPARTMENTS[0], 2)
	check_geometry(scene, scene.find_child("DeskGifts", true, false))
	print("GIFT GEOMETRY CHECKS: ", checks, " / FAILURES: ", failures.size())
	await unload_department(scene)
	get_tree().quit(0 if failures.is_empty() else 1)
