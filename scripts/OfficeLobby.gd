extends Node3D

@onready var player = get_node_or_null("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player:
		player.is_paused = true

	# 2. Settle the physics engine before triggering anything
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Unpause here if there is no opening dialogue/cutscene:
	if player:
		player.is_paused = false
