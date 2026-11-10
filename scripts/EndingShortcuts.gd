extends CanvasLayer

# Temporary playtest shortcuts. Set false or remove this autoload when finished.
# Release exports never enable these shortcuts.
const ENABLED := true
const INTRO_SCENE := preload("res://scene/ending_intro.tscn")
const Catalog := preload("res://scripts/EndingCatalog.gd")
const ENDING_KEYS := {
	KEY_F1: "algorithm_reformer",
	KEY_F2: "another_cog_in_the_machine",
	KEY_F3: "cold_efficiency",
	KEY_F4: "conflict_of_interest",
	KEY_F5: "stagnant_survival",
	KEY_F6: "terminated",
	KEY_F7: "clean_exit"
}

var _preview: Control
var _artwork: TextureRect
var _intro: Control
var _was_paused: bool
var _previous_mouse_mode: Input.MouseMode
var _previous_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	set_process_input(ENABLED and OS.is_debug_build())


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if ENDING_KEYS.has(event.keycode):
		if SceneTransition.is_transitioning:
			return
		get_viewport().set_input_as_handled()
		_show_preview(event.keycode)
	elif event.keycode == KEY_ESCAPE and _is_preview_open():
		get_viewport().set_input_as_handled()
		_close_preview()


func _is_preview_open() -> bool:
	return is_instance_valid(_preview) and _preview.visible


func _show_preview(keycode: int) -> void:
	if not is_instance_valid(_preview):
		_build_preview()
	if not _is_preview_open():
		_was_paused = get_tree().paused
		_previous_mouse_mode = Input.mouse_mode
		_previous_focus = get_viewport().gui_get_focus_owner()
	var ending_id: String = ENDING_KEYS[keycode]
	_artwork.texture = load(Catalog.get_presentation(ending_id)["image"]) as Texture2D
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_preview.show()
	_intro.show_ending(ending_id)


func _build_preview() -> void:
	_preview = Control.new()
	_preview.name = "EndingPreview"
	_preview.visible = false
	_preview.focus_mode = Control.FOCUS_ALL
	add_child(_preview)
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.gui_input.connect(_on_preview_input)

	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_artwork = TextureRect.new()
	_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(_artwork)
	_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_intro = INTRO_SCENE.instantiate()
	_preview.add_child(_intro)
	_intro.continued.connect(_on_intro_continued)


func _on_intro_continued() -> void:
	_preview.grab_focus()


func _on_preview_input(event: InputEvent) -> void:
	if _intro.visible:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var accepted := event.is_action_pressed("ui_accept") and not event.is_echo()
	if clicked or accepted:
		_preview.accept_event()
		_close_preview()


func _close_preview() -> void:
	GameMusic.clear_ending_music(_preview)
	_intro.release_focus()
	_intro.hide()
	_preview.release_focus()
	_preview.hide()
	get_tree().paused = _was_paused
	Input.mouse_mode = _previous_mouse_mode
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null
