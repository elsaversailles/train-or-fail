extends CanvasLayer

signal transition_finished

const TITLE_TEXTURE := preload("res://images/MainMenu/Game Title.png")

var color_rect: ColorRect
var loading_screen: Control
var loading_label: Label
var progress_bar: ProgressBar
var is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

	loading_screen = Control.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	loading_screen.visible = false
	add_child(loading_screen)

	var background := ColorRect.new()
	background.color = Color(0.055, 0.085, 0.13)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(360, 0)
	content.add_theme_constant_override("separation", 24)
	center.add_child(content)

	var title := TextureRect.new()
	title.texture = TITLE_TEXTURE
	title.custom_minimum_size = Vector2(320, 185)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(title)

	loading_label = Label.new()
	loading_label.text = "LOADING..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.54))
	loading_label.add_theme_font_size_override("font_size", 20)
	content.add_child(loading_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(360, 9)
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	content.add_child(progress_bar)

func change_scene(target_path: String, fade_duration: float = 0.5) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	progress_bar.value = 0
	loading_screen.modulate.a = 1.0
	loading_screen.visible = true
	# Let the loading screen render before requesting the next scene.
	await get_tree().process_frame

	var request_error := ResourceLoader.load_threaded_request(target_path)
	if request_error != OK:
		_finish_failed_load(target_path, request_error)
		return

	var progress: Array = []
	while true:
		var status := ResourceLoader.load_threaded_get_status(target_path, progress)
		if not progress.is_empty():
			progress_bar.value = clampf(float(progress[0]) * 100.0, 0.0, 100.0)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_finish_failed_load(target_path, FAILED)
			return
		await get_tree().process_frame

	var next_scene := ResourceLoader.load_threaded_get(target_path) as PackedScene
	if next_scene == null:
		_finish_failed_load(target_path, ERR_FILE_CORRUPT)
		return
	progress_bar.value = 100
	loading_label.text = "ALMOST THERE..."
	var change_error := get_tree().change_scene_to_packed(next_scene)
	if change_error != OK:
		_finish_failed_load(target_path, change_error)
		return

	await get_tree().process_frame
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(loading_screen, "modulate:a", 0.0, fade_duration)
	await tween.finished
	loading_screen.visible = false
	loading_screen.modulate.a = 1.0
	loading_label.text = "LOADING..."
	is_transitioning = false
	transition_finished.emit()

func reload_scene(fade_duration: float = 0.5) -> void:
	if get_tree().current_scene != null:
		change_scene(get_tree().current_scene.scene_file_path, fade_duration)

func _finish_failed_load(target_path: String, error: Error) -> void:
	push_error("Could not load scene %s (error %d)" % [target_path, error])
	loading_screen.visible = false
	loading_label.text = "LOADING..."
	is_transitioning = false
	get_tree().paused = false

func fade_to_black(fade_duration: float = 0.5) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished

func fade_from_black(fade_duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
