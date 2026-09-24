extends Area3D

@export var supervisor_npc: Node3D
@export var supervisor_bubble: Node3D
@export var supervisor_interact_body: StaticBody3D
@export var model_needs_flip: bool = true

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_triggered:
		var current_day = int(SaveManager.current_save_data.get("current_day", 1))

		if current_day == 1:
			has_triggered = true
			play_callout("You’re the new hire?, cmere talk to me.")
		elif current_day == 4:
			has_triggered = true
			play_callout("Hey! Hold up a sec before you head to the elevator.")
		elif current_day == 7:
			has_triggered = true
			play_callout("Hey hey hey, Your work now is almost complete and you’ll be regular in a few more training sessions, just like me!")

func play_callout(message: String) -> void:
	# 1. Rotate Jordan toward the approaching player
	var player = get_tree().get_first_node_in_group("player")
	if supervisor_npc and player:
		var target_pos = player.global_position
		target_pos.y = supervisor_npc.global_position.y
		supervisor_npc.look_at(target_pos, Vector3.UP)
		if model_needs_flip:
			supervisor_npc.rotate_y(PI)

	# 2. Show the callout speech bubble
	if supervisor_bubble:
		supervisor_bubble.display_text(message)
		await supervisor_bubble.finished_displaying
		await get_tree().create_timer(3.0).timeout
		supervisor_bubble.visible = false

	# 3. Allow E-key interaction on the supervisor
	if supervisor_interact_body:
		supervisor_interact_body.can_talk = true

	# 4. Remove the trigger for this session
	queue_free()
