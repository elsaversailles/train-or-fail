extends CanvasLayer

signal transition_finished

@onready var color_rect = ColorRect.new()
var is_transitioning: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Top of everything
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
	
	# Fade out to black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# Load new scene
	get_tree().change_scene_to_file(target_path)
	
	# Wait a frame so the new scene mounts and runs its _ready()
	await get_tree().process_frame
	
	# Fade in from black
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	is_transitioning = false
	
	# CRITICAL SAFETY NET: Always unpause the engine when arriving at a new scene!
	get_tree().paused = false
	
	# Notify listening scenes (like dock.gd) that fade-in is complete
	transition_finished.emit()

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
