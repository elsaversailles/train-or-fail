extends Camera3D

@export_group("Scene Transition")
@export var next_scene_path: String = "res://scene/dock.tscn"
## How many seconds to hold on the boat before switching scenes
@export var pause_after_zoom: float = 1.0

@export_group("Timing Settings")
## Brief pause after the scene renders before zooming starts
@export var start_delay: float = 0.5
## Duration of the opening zoom in seconds
@export var zoom_duration: float = 2.5

@export_group("Zoom Settings")
@export var start_position_offset: Vector3 = Vector3(0.0, 4.0, 10.0)
@export var zoom_fov: bool = true
@export var start_fov: float = 75.0
@export var target_fov: float = 45.0

func _ready() -> void:
	var final_position: Vector3 = position
	position = final_position + start_position_offset
	if zoom_fov:
		fov = start_fov

	# 1. Wait until the GPU has fully drawn the first frame
	await RenderingServer.frame_post_draw

	# 2. Brief pause before the zoom starts
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout

	# 3. Perform the smooth zoom
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "position", final_position, zoom_duration)
	if zoom_fov:
		tween.tween_property(self, "fov", target_fov, zoom_duration)

	# 4. Wait for the camera to finish zooming in
	await tween.finished

	# 5. Hold on the zoomed-in shot
	if pause_after_zoom > 0.0:
		await get_tree().create_timer(pause_after_zoom).timeout

	# 6. Transition to the Office Lobby using your SceneTransition autoload
	SceneTransition.change_scene(next_scene_path)
