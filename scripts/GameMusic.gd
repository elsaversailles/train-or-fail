extends Node

const TRACKS := {
	"menu": "res://assets/music/game music/Main Menu.mp3",
	"overworld": "res://assets/music/game music/Overworld.mp3",
	"lobby": "res://assets/music/game music/Lobby.mp3",
	"elevator": "res://assets/music/game music/Elevator.mp3",
	"gameplay": "res://assets/music/game music/Gameplay.mp3",
	"bad_ending": "res://assets/music/game music/Bad Ending.mp3",
}
const SCENE_TRACKS := {
	"main_menu": "menu", "slots_menu": "menu", "about_us_panel": "menu",
	"ending_gallery": "menu", "office_lobby": "lobby", "elevator": "elevator",
	"FraudDetection": "gameplay", "KnowYourCustomer": "gameplay", "CreditScoring": "gameplay",
	"outside_world": "overworld", "boat": "overworld", "dock": "overworld",
	"Jeepney": "overworld", "apartment": "overworld",
}
const LOADING_TRACKS := [
	"res://assets/music/loading screen.mp3",
	"res://assets/music/random loadscreena.mp3",
	"res://assets/music/randomized loadscreen.mp3",
]

var _player: AudioStreamPlayer
var _streams: Dictionary = {}
var _scene_track := ""
var _loading := false
var _current_path := ""
var _ending_overrides: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = &"Music"
	add_child(_player)
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	_scene_track = str(SCENE_TRACKS.get(scene.scene_file_path.get_file().get_basename(), "")) if scene else ""
	_refresh_music()


func begin_loading() -> void:
	_loading = true
	_play_path(LOADING_TRACKS.pick_random())


func end_loading() -> void:
	_loading = false
	_on_scene_changed()


func set_ending_music(owner_node: Node, ending_id: String) -> void:
	# Keep the ending track through its title card and artwork. Preview owners
	# can temporarily override the game and restore its music when dismissed.
	clear_ending_music(owner_node, false)
	_ending_overrides.append({
		"owner": weakref(owner_node),
		"track": "bad_ending" if ending_id == "terminated" else "",
	})
	var cleanup := clear_ending_music.bind(owner_node)
	if not owner_node.tree_exiting.is_connected(cleanup):
		owner_node.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	_refresh_music()


func clear_ending_music(owner_node: Node, refresh: bool = true) -> void:
	for index in range(_ending_overrides.size() - 1, -1, -1):
		var existing: Node = _ending_overrides[index]["owner"].get_ref()
		if existing == null or existing == owner_node:
			_ending_overrides.remove_at(index)
	if refresh:
		_refresh_music()


func _refresh_music() -> void:
	if _loading:
		return
	var track := _scene_track
	if not _ending_overrides.is_empty():
		var ending_track: String = _ending_overrides.back()["track"]
		if not ending_track.is_empty():
			track = ending_track
	_play_path(str(TRACKS.get(track, "")))


func _play_path(path: String) -> void:
	if path == _current_path and _player.playing:
		return
	_player.stop()
	_current_path = path
	if path.is_empty():
		_player.stream = null
		return
	if not _streams.has(path):
		var stream := load(path) as AudioStreamMP3
		if stream == null:
			push_error("Could not load music: " + path)
			return
		stream = stream.duplicate() as AudioStreamMP3
		stream.loop = true
		_streams[path] = stream
	_player.stream = _streams[path]
	_player.play()
