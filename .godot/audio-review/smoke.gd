extends SceneTree

var failures: Array[String] = []
var checks := 0
var music: Node
var settings: Node
var effects: Node
var transitions: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("AUDIO TEST FAILED: " + label)

func track_is(filename: String) -> bool:
	return music._current_path.get_file() == filename and music._player.playing

func enter_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	return event

func _run() -> void:
	var user_dir := OS.get_user_data_dir().replace("\\", "/")
	print("AUDIO_TEST_USER_DIR=" + user_dir)
	if not user_dir.contains("/.godot/audio-review/userdata/"):
		push_error("Refusing audio tests outside isolated user data")
		quit(2)
		return
	music = root.get_node("GameMusic")
	settings = root.get_node("SettingsManager")
	effects = root.get_node("SoundEffects")
	transitions = root.get_node("SceneTransition")
	if "verify_persistence" in OS.get_cmdline_user_args():
		check(is_equal_approx(settings.master_volume, 0.42), "Master restored at process startup")
		check(is_equal_approx(settings.music_volume, 0.17), "Music restored at process startup")
		check(is_equal_approx(settings.sfx_volume, 0.63), "SFX restored at process startup")
		for pair in [["Master", 0.42], ["Music", 0.17], ["SFX", 0.63]]:
			check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(pair[0]))), pair[1]), pair[0] + " restored on actual bus")
		_finish()
		return
	for bus_name in ["Master", "Music", "SFX"]:
		check(AudioServer.get_bus_index(bus_name) >= 0, bus_name + " bus exists")
		settings.set_audio_volume(bus_name, 1.0)
	for bus_name in ["Music", "SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		check(AudioServer.get_bus_send(bus_index) == &"Master", bus_name + " sends to Master")
		settings.set_audio_volume(bus_name, 0.0)
		check(AudioServer.is_bus_mute(bus_index), bus_name + " zero mutes bus")
		var other := "SFX" if bus_name == "Music" else "Music"
		check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(other)), bus_name + " mute preserves other bus")
		check(not AudioServer.is_bus_mute(0), bus_name + " mute preserves Master/floppy")
		settings.set_audio_volume(bus_name, 0.35)
		check(not AudioServer.is_bus_mute(bus_index), bus_name + " restores from mute")
		check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.35), bus_name + " slider applies linear volume")
	settings.set_audio_volume("Master", 0.0)
	check(AudioServer.is_bus_mute(0), "Master zero mutes all audio")
	settings.set_audio_volume("Master", 1.0)
	check(not AudioServer.is_bus_mute(0), "Master restores from mute")
	check(music.process_mode == Node.PROCESS_MODE_ALWAYS and music._player.bus == &"Music", "Music always processes on Music bus")
	check(effects.process_mode == Node.PROCESS_MODE_ALWAYS, "SoundEffects always processes")
	check(effects._players.size() == 8, "SoundEffects player pool created")
	for effect_id in effects.STREAMS:
		effects.play(effect_id)
		var voice = effects._players[(effects._next_voice + 7) % 8]
		check(voice.bus == &"SFX" and voice.playing and not voice.stream.loop, effect_id + " plays one shot on SFX")
	for voice in effects._players:
		voice.stop()
	change_scene_to_file("res://scene/main_menu.tscn")
	await scene_changed
	await process_frame
	check(track_is("Main Menu.mp3"), "Real main menu starts new music")
	check(current_scene.find_child("Music", true, false) == null, "Old local menu player removed")
	var menu_settings = current_scene.get_node("Main Menu/SettingsPanel")
	check(menu_settings.get_node("MusicControl").audio_bus_name == "Master", "Master slider connected")
	check(menu_settings.get_node("MusicVolumeControl").audio_bus_name == "Music", "Music slider connected")
	check(menu_settings.get_node("SfxVolumeControl").audio_bus_name == "SFX", "SFX slider connected")
	var original_path: String = current_scene.scene_file_path
	var mappings := {
		"main_menu": "Main Menu.mp3", "slots_menu": "Main Menu.mp3", "about_us_panel": "Main Menu.mp3",
		"office_lobby": "Lobby.mp3", "elevator": "Elevator.mp3",
		"FraudDetection": "Gameplay.mp3", "KnowYourCustomer": "Gameplay.mp3", "CreditScoring": "Gameplay.mp3",
		"outside_world": "Overworld.mp3", "boat": "Overworld.mp3", "dock": "Overworld.mp3", "apartment": "Overworld.mp3",
	}
	for scene_name in mappings:
		current_scene.scene_file_path = "res://scene/" + scene_name + ".tscn"
		music._on_scene_changed()
		check(track_is(mappings[scene_name]) and music._player.stream.loop, scene_name + " selects looping matching track")
	current_scene.scene_file_path = original_path
	music._on_scene_changed()
	await create_timer(0.12).timeout
	var playback = music._player.get_stream_playback()
	music._on_scene_changed()
	check(music._player.get_stream_playback() == playback, "Refreshing same theme preserves playback")
	for loading_path in music.LOADING_TRACKS:
		music._play_path(loading_path)
		check(track_is(loading_path.get_file()) and music._player.stream.loop, "Loading track usable: " + loading_path.get_file())
	music._on_scene_changed()
	transitions.change_scene("res://scene/slots_menu.tscn", 0.01)
	check(music._loading and music._current_path in music.LOADING_TRACKS, "Real transition starts loading music")
	await transitions.transition_finished
	check(current_scene.scene_file_path.ends_with("slots_menu.tscn") and track_is("Main Menu.mp3"), "Real slots transition restores menu theme")
	check(not music._loading, "Transition clears loading state")
	var effect_survivor = effects._players[effects._next_voice]
	effects.play("new_game")
	transitions.change_scene("res://scene/main_menu.tscn", 0.01)
	await transitions.transition_finished
	check(is_instance_valid(effect_survivor) and effect_survivor.is_inside_tree(), "Effect players survive scene changes")
	check(track_is("Main Menu.mp3"), "Return to real main menu works")
	var ending_owner := Control.new()
	current_scene.add_child(ending_owner)
	var intro = load("res://scene/ending_intro.tscn").instantiate()
	ending_owner.add_child(intro)
	intro.show_ending("terminated")
	check(track_is("Bad Ending.mp3") and music._player.stream.loop, "Terminated starts looping Bad Ending")
	intro._gui_input(enter_event())
	check(not intro.visible and track_is("Bad Ending.mp3"), "Ending artwork keeps ending music")
	ending_owner.queue_free()
	await process_frame
	check(track_is("Main Menu.mp3"), "Freeing ending owner restores scene theme")
	var shortcuts = root.get_node("EndingShortcuts")
	shortcuts._show_preview(KEY_F6)
	check(paused and track_is("Bad Ending.mp3"), "F6 preview plays ending while paused")
	check(music._player.can_process() and effects._players[0].can_process(), "Music and SFX process during pause")
	shortcuts._intro._gui_input(enter_event())
	check(track_is("Bad Ending.mp3"), "Preview artwork keeps ending music")
	shortcuts._close_preview()
	check(not paused and track_is("Main Menu.mp3"), "Closing preview restores menu and pause state")
	shortcuts._show_preview(KEY_F6)
	shortcuts._show_preview(KEY_F1)
	check(track_is("Main Menu.mp3"), "Switching to nonterminated preview clears Bad Ending")
	shortcuts._close_preview()
	var gallery = load("res://scene/ending_gallery.tscn").instantiate()
	current_scene.add_child(gallery)
	var entry = gallery.entries.get_child(0)
	gallery._open_ending("terminated", entry)
	check(track_is("Bad Ending.mp3"), "Gallery ending preview changes music")
	gallery.intro._gui_input(enter_event())
	check(gallery.artwork.visible and track_is("Bad Ending.mp3"), "Gallery artwork retains ending music")
	gallery._return_to_entries()
	check(track_is("Main Menu.mp3"), "Gallery back restores menu theme")
	gallery.queue_free()
	await process_frame
	print("EXPECTED_LOAD_FAILURE_BEGIN")
	transitions.change_scene("res://scene/audio_test_missing_scene.tscn", 0.01)
	while transitions.is_transitioning:
		await process_frame
	print("EXPECTED_LOAD_FAILURE_END")
	check(track_is("Main Menu.mp3") and not music._loading, "Failed scene load restores current theme")
	check(current_scene.scene_file_path.ends_with("main_menu.tscn"), "Failed scene load preserves current scene")
	for department in ["FraudDetection", "KnowYourCustomer", "CreditScoring"]:
		var packed = load("res://scene/%s/%s.tscn" % [department, department]) as PackedScene
		check(packed != null, department + " resource loads without deleted music")
		if packed:
			var state = packed.get_state()
			var old_music := false
			for index in state.get_node_count():
				old_music = old_music or state.get_node_name(index) == &"MusicGameplay"
			check(not old_music, department + " duplicate player removed")
	settings.set_audio_volume("Master", 0.42)
	settings.set_audio_volume("Music", 0.17)
	settings.set_audio_volume("SFX", 0.63)
	var persisted := ConfigFile.new()
	check(persisted.load("user://settings.cfg") == OK, "Settings file saved")
	check(is_equal_approx(persisted.get_value("Audio", "music_volume"), 0.17), "Music setting persisted")
	check(is_equal_approx(persisted.get_value("Audio", "sfx_volume"), 0.63), "SFX setting persisted")
	_finish()

func _finish() -> void:
	print("AUDIO_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures:
		print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
