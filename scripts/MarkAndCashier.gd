extends Area3D

@export var mark_npc: Node3D
@export var cashier_npc: Node3D

@export var mark_bubble: Node3D
@export var cashier_bubble: Node3D

@export var mark_interact_body: StaticBody3D

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	print("Something touched the Day 2 trigger: ", body.name)
	if body.is_in_group("player") and not has_triggered:
		var current_day = SaveManager.current_save_data.get("current_day", 1)
		
		# Only runs on Day 2
		if current_day == 2:
			has_triggered = true
			play_ambient_conversation()

func play_ambient_conversation():
	# 1. Turn them to face each other
	if mark_npc and cashier_npc:
		var target_cashier = cashier_npc.global_position
		target_cashier.y = mark_npc.global_position.y
		mark_npc.look_at(target_cashier, Vector3.UP)
		mark_npc.rotate_y(PI) # Flips Mark 180 degrees to correct the inverted .glb armature
		
		var target_mark = mark_npc.global_position
		target_mark.y = cashier_npc.global_position.y
		cashier_npc.look_at(target_mark, Vector3.UP)

	# 2. Mark speaks
	mark_bubble.display_text("I swear the card works! The bank just keeps flagging it every time I move to a new bench. They think someone stole my life savings!")
	await mark_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	mark_bubble.visible = false

	await get_tree().create_timer(0.5).timeout

	# 3. Cashier replies
	cashier_bubble.display_text("Look, man, the card is declining. I can't give you the bread.")
	await cashier_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	cashier_bubble.visible = false

	# 4. Unlock Mark's interaction for Dialogic
	if mark_interact_body:
		mark_interact_body.can_talk = true

	# 5. Remove trigger
	queue_free()
