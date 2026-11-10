extends ColorRect

signal closed

const Catalog := preload("res://scripts/EndingCatalog.gd")
const ENTRY_SCENE := preload("res://scene/ending_gallery_entry.tscn")
const LOCKED_SHADER := preload("res://shader/locked_ending.gdshader")

@onready var window: NinePatchRect = $Window
@onready var entries: GridContainer = $Window/Entries
@onready var close_button: Button = $Window/Close
@onready var intro = $EndingIntro
@onready var artwork: ColorRect = $Artwork
@onready var picture: TextureRect = $Artwork/Picture
@onready var back_button: Button = $Artwork/Back

var selected_entry: Button


func _ready() -> void:
	close_button.pressed.connect(closed.emit)
	back_button.pressed.connect(_return_to_entries)
	intro.continued.connect(_show_artwork)
	resized.connect(_fit_window)
	_fit_window()

	$Window/Count.text = "%d/%d endings" % [SaveManager.get_unlocked_ending_count(), Catalog.ENDINGS.size()]
	var locked_material := ShaderMaterial.new()
	locked_material.shader = LOCKED_SHADER
	for ending_id in Catalog.ENDINGS:
		var ending: Dictionary = Catalog.ENDINGS[ending_id]
		var entry: Button = ENTRY_SCENE.instantiate()
		entries.add_child(entry)
		var thumbnail: TextureRect = entry.get_node("Thumbnail")
		var caption: Label = entry.get_node("Caption")
		thumbnail.texture = load(ending.image)
		if SaveManager.is_ending_unlocked(ending_id):
			caption.text = ending.title
			entry.tooltip_text = "View %s" % ending.title
			entry.pressed.connect(_open_ending.bind(ending_id, entry))
		else:
			entry.disabled = true
			entry.focus_mode = Control.FOCUS_NONE
			entry.mouse_default_cursor_shape = Control.CURSOR_ARROW
			thumbnail.material = locked_material
			caption.text = "Locked"
			caption.modulate = Color(0.72, 0.76, 0.81)
		entry.accessibility_name = caption.text
	close_button.grab_focus()


func _fit_window() -> void:
	var fit := minf(1.0, minf(size.x / (window.size.x + 24.0), size.y / (window.size.y + 24.0)))
	window.scale = Vector2.ONE * fit
	window.position = (size - window.size * fit) * 0.5


func _open_ending(ending_id: String, entry: Button) -> void:
	selected_entry = entry
	picture.texture = entry.get_node("Thumbnail").texture
	window.hide()
	intro.show_ending(ending_id)


func _show_artwork() -> void:
	artwork.show()
	back_button.grab_focus()


func _return_to_entries() -> void:
	GameMusic.clear_ending_music(self)
	intro.hide()
	artwork.hide()
	picture.texture = null
	window.show()
	selected_entry.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if window.visible:
			closed.emit()
		else:
			_return_to_entries()
