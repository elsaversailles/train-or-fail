extends Node3D
## Gifts belong to the current slot's decisions, like the office certificates.

const GIFTS := {
	"Bread": "tita_elena",
	"ToyCar": "jericho_santur",
	"ToyTank": "mark_krazy",
	"FirstAidKit": "nurse_clara",
	"Yarn": "grandpa",
}

func _ready() -> void:
	SaveManager.special_decision_changed.connect(_on_special_decision_changed)
	refresh()


func refresh() -> void:
	for gift_name in GIFTS:
		get_node(gift_name).visible = SaveManager.is_desk_gift_available(GIFTS[gift_name])


func _on_special_decision_changed(_character_id: String, _decision: String) -> void:
	refresh()
