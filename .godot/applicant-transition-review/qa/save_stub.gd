extends Node

var current_save_data: Dictionary = {}
var decisions: Array = []

func record_special_decision(character_id: String, decision: String) -> void:
	decisions.append([character_id, decision])
