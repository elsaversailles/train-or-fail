extends "res://scripts/WaypointMarker.gd"

@export var tutorial: Control
@export var player: CharacterBody3D
@export var floppy_disk: RigidBody3D
@export var cartridge: Node3D
@export var monitor: Node3D
@export var monitor_screen: Node3D
@export var guide_disk_setup: bool = false

# Keep the outdoor waypoint's icon, bounce, scaling and off-screen guidance,
# but choose targets from the workstation tutorial instead of the story day.
func setup_day_target() -> void:
	_update_tutorial_target()

func _process(delta: float) -> void:
	_update_tutorial_target()
	super._process(delta)

func _update_tutorial_target() -> void:
	current_target = null
	visible = false
	if not is_instance_valid(tutorial) or tutorial.is_queued_for_deletion():
		return
	if tutorial.get("tutorial_step") != -1:
		return
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return
	if player.get("is_paused") or player.get("is_in_dialogue") or player.get("is_focusing_screen"):
		return

	if guide_disk_setup:
		if not is_instance_valid(floppy_disk):
			return
		if not floppy_disk.get("is_inserted"):
			if floppy_disk.get("is_held"):
				current_target = cartridge
				current_vertical_offset = 0.65
			else:
				current_target = floppy_disk
				current_vertical_offset = 0.45
			return
		# Insertion takes two seconds. Keep pointing at the cartridge until
		# the green light comes on and the desktop is ready to use.
		if not is_instance_valid(monitor_screen) or not monitor_screen.visible:
			current_target = cartridge
			current_vertical_offset = 0.65
			return

	current_target = monitor
	current_vertical_offset = 2.15
