extends CanvasLayer

@onready var color_rect = ColorRect.new()
var is_transitioning: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# top of everything
	layer = 100 
	
	# Set it to transparent black to start
	color_rect.color = Color(0, 0, 0, 0) 
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

# 1. Standard Scene Change Transition
func change_scene(target_path: String, fade_duration: float = 0.5):
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	get_tree().change_scene_to_file(target_path)
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	is_transitioning = false
	
	# CRITICAL SAFETY NET: Always unpause the engine when arriving at a new scene!
	get_tree().paused = false

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
