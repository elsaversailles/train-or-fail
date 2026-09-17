extends Area3D

@export var target_day: int = 8

@export var jericho_npc: Node3D
@export var joice_npc: Node3D

@export var jericho_bubble: Node3D
@export var joice_bubble: Node3D

@export var jericho_interact_body: StaticBody3D 

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_triggered:
		var current_day = SaveManager.current_save_data.get("current_day", 1)
		
		# Only activates on Day 8
		if current_day == target_day:
			has_triggered = true
			play_ambient_conversation()

func play_ambient_conversation():
	# 1. Rotate them to face each other
	if jericho_npc and joice_npc:
		var target_joice = joice_npc.global_position
		target_joice.y = jericho_npc.global_position.y
		jericho_npc.look_at(target_joice, Vector3.UP)
		# jericho_npc.rotate_y(PI) # Uncomment if Jericho faces backwards

		var target_jericho = jericho_npc.global_position
		target_jericho.y = joice_npc.global_position.y
		joice_npc.look_at(target_jericho, Vector3.UP)
		# joice_npc.rotate_y(PI) # Uncomment if Joice faces backwards

	# 2. Dialogue sequence
	jericho_bubble.display_text("Joice, our fleet expansion plan for local commercial buyers like Adrian, Carlo, and Miguel is solid.")
	await jericho_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	jericho_bubble.display_text("But without a higher credit line from the bank, we can't secure the vehicle stock.")
	await jericho_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	jericho_bubble.visible = false

	await get_tree().create_timer(0.5).timeout

	joice_bubble.display_text("If the bank flags us or gives us a low approval, we'll have to keep turning away bulk business customers.")
	await joice_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	joice_bubble.visible = false

	# 3. Unlock Jericho for the player interaction
	if jericho_interact_body:
		jericho_interact_body.can_talk = true

	queue_free()
