extends StaticBody3D

@onready var idle_screen = $MeshInstance3D
@onready var focus_point = $Marker3D

var is_focused = false

func interact():
	if is_focused:
		return
		
	is_focused = true
	if idle_screen:
		idle_screen.visible = false
	
	# Send this monitor instance to the player so it can talk back
	get_tree().call_group("player", "set_computer_focus", focus_point.global_transform, self)

# Add this new function for the player to call
func set_idle_visible(p_visible: bool):
	is_focused = !p_visible
	if idle_screen:
		idle_screen.visible = p_visible
