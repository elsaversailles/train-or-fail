extends StaticBody3D

@onready var idle_screen = $"."
@onready var focus_point = $Marker3D

var is_focused = false

func interact():
	# 1. THE GUARD: If already focused, stop immediately.
	if is_focused:
		print("Already in use!")
		return
		
	is_focused = true
	input_ray_pickable = false
	
	if idle_screen:
		idle_screen.visible = false
	
	# Send this monitor instance to the player
	get_tree().call_group("player", "set_computer_focus", focus_point.global_transform, self)

func set_idle_visible(p_visible: bool):
	# When p_visible is true (idle), is_focused becomes false (interactable again)
	is_focused = !p_visible
	
	if idle_screen:
		idle_screen.visible = p_visible
