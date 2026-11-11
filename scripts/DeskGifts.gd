extends Node3D
## Gifts belong to the current slot's decisions, like the office certificates.

const GIFTS := {
	"Bread": "tita_elena",
	"ToyCar": "jericho_santur",
	"ToyTank": "mark_krazy",
	"FirstAidKit": "nurse_clara",
}


func _ready() -> void:
	SaveManager.special_decision_changed.connect(_on_special_decision_changed)
	refresh()


func refresh() -> void:
	for gift_name in GIFTS:
		get_node(gift_name).visible = SaveManager.get_special_decision(GIFTS[gift_name]) == "legit"
	var data := SaveManager.current_save_data
	var secret_round: bool = data.get("is_grandpa_shift", false) or data.get("grandpa_round_completed", false)
	var secret_ending := SaveManager.get_completed_ending_id(data) == "conflict_of_interest"
	$Yarn.visible = SaveManager.get_special_decision("grandpa") == "legit" and (secret_round or secret_ending)


func _on_special_decision_changed(_character_id: String, _decision: String) -> void:
	refresh()
