extends Area3D

@export var target_day: int = 7

@export var clara_npc: Node3D
@export var supplier_npc: Node3D

@export var clara_bubble: Node3D
@export var supplier_bubble: Node3D

# Reference to Clara's StaticBody3D to unlock interaction
@export var clara_interact_body: StaticBody3D

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	print("Something touched the Day 2 trigger: ", body.name)
	if body.is_in_group("player") and not has_triggered:
		var current_day = SaveManager.current_save_data.get("current_day", 1)
		
		if current_day == target_day:
			has_triggered = true
			play_ambient_conversation()

func play_ambient_conversation():
	# 1. Turn them to face each other
	if clara_npc and supplier_npc:
		var target_supplier = supplier_npc.global_position
		target_supplier.y = clara_npc.global_position.y
		clara_npc.look_at(target_supplier, Vector3.UP)
		clara_npc.rotate_y(PI) # Uncomment if Clara's model faces backward

		var target_clara = clara_npc.global_position
		target_clara.y = supplier_npc.global_position.y
		supplier_npc.look_at(target_clara, Vector3.UP)
		supplier_npc.rotate_y(PI) # Uncomment if Supplier's model faces backward

	# 2. Clara speaks
	clara_bubble.display_text("I know it’s a risk, but this neighborhood really needs a local, low-cost community clinic.")
	await clara_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	
	clara_bubble.display_text("If the bank approves my loan for proper diagnostic tools, people won't have to travel an hour to the central hospital..")
	await clara_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	clara_bubble.visible = false

	await get_tree().create_timer(0.5).timeout

	# 3. Supplier replies
	supplier_bubble.display_text("Hope it goes through, Clara. Medical gear isn't cheap, and the bank might look hard at your low profit margins.")
	await supplier_bubble.finished_displaying
	await get_tree().create_timer(2.0).timeout
	supplier_bubble.visible = false

	# 4. Unlock Clara's interaction for Dialogic
	if clara_interact_body:
		clara_interact_body.can_talk = true

	# 5. Clean up trigger
	queue_free()
