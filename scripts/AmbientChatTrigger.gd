extends Area3D

@export var grandpa_npc: Node3D
@export var assistant_npc: Node3D
@export var grandpa_bubble: Node3D
@export var assistant_bubble: Node3D

# Direct link to Grandpa's StaticBody3D so we can unlock his Dialogic chat
@export var grandpa_interact_body: StaticBody3D 

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_triggered:
		# Check if it is Day 1 using your SaveManager
		var current_day = SaveManager.current_save_data.get("current_day", 1)
		
		if current_day == 1:
			has_triggered = true
			play_ambient_conversation()

func play_ambient_conversation():
	# 1. Make them turn to face each other
	if grandpa_npc and assistant_npc:
		var target_assistant = assistant_npc.global_position
		target_assistant.y = grandpa_npc.global_position.y 
		grandpa_npc.look_at(target_assistant, Vector3.UP)
		grandpa_npc.rotate_y(PI) # Flips Grandpa 180 degrees to face the assistant
		
		var target_grandpa = grandpa_npc.global_position
		target_grandpa.y = assistant_npc.global_position.y
		assistant_npc.look_at(target_grandpa, Vector3.UP)
		assistant_npc.rotate_y(PI)
		
	# 2. Grandpa speaks
	grandpa_bubble.display_text("Man, rush-order season is right around the corner. We gotta stock flour early before local prices spike...")
	
	await grandpa_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout 
	grandpa_bubble.visible = false
	
	# Short pause between speakers
	await get_tree().create_timer(0.5).timeout 
	
	# 3. Assistant replies
	assistant_bubble.display_text("Yeah, but that overseas supplier demands the full payment upfront...")
	
	await assistant_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	assistant_bubble.visible = false
	
	# 4. Unlock Grandpa's interactive Dialogic chat!
	if grandpa_interact_body:
		grandpa_interact_body.can_talk = true
	
	# 5. Delete the invisible trigger so it never happens again
	queue_free()
