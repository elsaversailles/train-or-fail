extends CanvasLayer

@onready var color_rect = ColorRect.new()

func _ready():
	# Make sure the black screen is on top of ALL other UI
	layer = 100 
	
	# Set it to transparent black to start
	color_rect.color = Color(0, 0, 0, 0) 
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

# 1. Standard Scene Change Transition
func change_scene(target_path: String, fade_duration: float = 0.5):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Block mouse clicks
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# Change the scene while it's completely black
	get_tree().change_scene_to_file(target_path)
	
	# Fade back in
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Allow clicks again

# 2. Manual Fades (For your Result Panel)
func fade_to_black(fade_duration: float = 0.5):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished

func fade_from_black(fade_duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
