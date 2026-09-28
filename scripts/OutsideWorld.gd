extends Node3D

# Safely reference the player if present in this scene
@onready var player = get_node_or_null("Player")

# Story days matching your specific timelines
const STORY_DAYS: Array[int] = [1, 2, 4, 7, 8]
const QUIET_TIMELINES: Array[String] = ["Quiet Days1", "Quiet Days2"]

func _ready() -> void:
	# 1. Freeze the player instantly so holding WASD doesn't push them into walls
	if player:
		player.is_paused = true

	# 2. Settle the physics engine before triggering anything
	await get_tree().physics_frame
	await get_tree().physics_frame

	play_daily_monologue()

func play_daily_monologue() -> void:
	var current_day: int = SaveManager.current_save_data.get("current_day", 1)
	var timeline_to_play: String = ""

	# Check if today has a dedicated story timeline
	if current_day in STORY_DAYS:
		timeline_to_play = "day" + str(current_day)
	else:
		# Randomly pick between your quiet day timelines
		timeline_to_play = QUIET_TIMELINES.pick_random()

	# Connect Dialogic end signal to restore movement once dialogue is complete
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	# Start Dialogic
	Dialogic.start(timeline_to_play)

func _on_timeline_ended() -> void:
	# Unfreeze the player after the monologue ends
	if player:
		player.is_paused = false
