extends Control

const GALLERY_SCENE := preload("res://scene/ending_gallery.tscn")
const Catalog := preload("res://scripts/EndingCatalog.gd")

@onready var settings_panel: Panel = $SettingsPanel
@onready var gallery_button: Button = $GalleryButton

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	settings_panel.visible = false
	settings_panel.visibility_changed.connect(func(): gallery_button.visible = not settings_panel.visible)
	$GalleryButton/Count.text = "%d/%d endings" % [SaveManager.get_unlocked_ending_count(), Catalog.ENDINGS.size()]

func _on_gallery_pressed() -> void:
	var gallery = GALLERY_SCENE.instantiate()
	$Buttons.hide()
	$TextureRect.hide()
	gallery_button.hide()
	gallery.closed.connect(func():
		gallery.queue_free()
		$Buttons.show()
		$TextureRect.show()
		gallery_button.show()
		gallery_button.grab_focus()
	)
	add_child(gallery)

func _on_new_game_pressed():
	# Call our new Autoload to handle the fade and load!
	SceneTransition.change_scene("res://scene/slots_menu.tscn")

func _on_settings_pressed():
	settings_panel.visible = true

func _on_about_us_pressed():
	SceneTransition.change_scene("res://scene/about_us_panel.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		settings_panel.hide()
