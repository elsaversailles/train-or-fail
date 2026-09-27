extends Node3D

# Story days matching your specific timelines
const STORY_DAYS: Array[int] = [1, 2, 4, 7, 8]
const QUIET_TIMELINES: Array[String] = ["Quiet Days1", "Quiet Days2"]

func _ready() -> void:
	# Give the scene and camera a moment to initialize after loading
	await get_tree().create_timer(0.4).timeout
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

	# Start Dialogic
	Dialogic.start(timeline_to_play)
