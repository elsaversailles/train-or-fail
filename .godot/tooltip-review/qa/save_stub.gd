extends "res://scripts/SaveManager.gd"
func get_save_path(slot: int) -> String:
 return "res://test_save_%d.dat" % slot
