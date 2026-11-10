extends Node

# These players live across scene changes so menu and save sounds can finish.
const STREAMS := {
	"button": preload("res://assets/music/sfx/Click of every button.mp3"),
	"click": preload("res://assets/music/sfx/Click.mp3"),
	"play": preload("res://assets/music/sfx/Click play from menu.mp3"),
	"slot": preload("res://assets/music/sfx/click save file.mp3"),
	"new_game": preload("res://assets/music/sfx/click new game from save file.mp3"),
	"load_game": preload("res://assets/music/sfx/Load Game.mp3"),
	"delete": preload("res://assets/music/sfx/Delete.mp3"),
	"accepted": preload("res://assets/music/sfx/Accepted.mp3"),
	"rejected": preload("res://assets/music/sfx/Rejected.mp3"),
	"slider": preload("res://assets/music/sfx/slider tick up and down.mp3"),
	"inspect": preload("res://assets/music/sfx/spinning char inpect button.mp3"),
}
const VOICE_COUNT := 8
const SLIDER_TICK_INTERVAL_MS := 60

var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_slider_tick_ms := -SLIDER_TICK_INTERVAL_MS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "Effect%d" % index
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)
	_register_existing_controls(get_tree().root)


func play(sound_id: String) -> void:
	if not STREAMS.has(sound_id):
		return
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_COUNT
	player.stream = STREAMS[sound_id]
	player.play()


# An empty sound ID reserves a button for its guarded action handler.
func set_button_sound(button: BaseButton, sound_id: String) -> void:
	button.set_meta("ui_sound", sound_id)


func _on_node_added(node: Node) -> void:
	# Wait until scene _ready() methods have initialized values and sound overrides.
	if node is BaseButton or node is Slider or node is TabBar:
		_register_control.call_deferred(node)


func _register_existing_controls(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_register_existing_controls(child)


func _register_control(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree() or node.has_meta("ui_sound_connected"):
		return
	if node is BaseButton:
		node.set_meta("ui_sound_connected", true)
		node.pressed.connect(_on_button_pressed.bind(node))
	elif node is Slider:
		node.set_meta("ui_sound_connected", true)
		node.value_changed.connect(_on_slider_changed.bind(node))
	elif node is TabBar:
		node.set_meta("ui_sound_connected", true)
		node.tab_clicked.connect(func(_tab: int): play("click"))


func _on_button_pressed(button: BaseButton) -> void:
	play(str(button.get_meta("ui_sound", "button")))


func _on_slider_changed(_value: float, slider: Slider) -> void:
	# Only user input should tick: opening settings and loading applicants stay quiet.
	if not slider.is_visible_in_tree() or not slider.has_focus():
		return
	var user_input := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for action in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_home", "ui_end", "ui_page_up", "ui_page_down"]:
		user_input = user_input or Input.is_action_pressed(action)
	if not user_input:
		return
	var now := Time.get_ticks_msec()
	if now - _last_slider_tick_ms >= SLIDER_TICK_INTERVAL_MS:
		_last_slider_tick_ms = now
		play("slider")
