extends Panel

@onready var buttons: Control = $"../Buttons"
@onready var settings_panel: Panel = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	settings_panel.visible = false
	buttons.visible = true
