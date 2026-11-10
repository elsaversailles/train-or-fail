extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("AMBIENCE FAILED: " + label)

func _run() -> void:
	var user_dir := OS.get_user_data_dir().replace("\\", "/")
	print("AMBIENCE_USER_DIR=" + user_dir)
	if not user_dir.contains("/.godot/audio-review/userdata/"):
		push_error("Refusing tests outside isolated user data")
		quit(2)
		return
	for rainy in [false, true]:
		var city = load("res://scripts/CityAtmosphere.gd").new()
		root.add_child(city)
		city._rainy = rainy
		city._start_ambience()
		var player = city.get_node("WeatherAmbience")
		var label := "Rain" if rainy else "Birds"
		check(player.stream != null, label + " stream imported")
		if player.stream:
			check(player.stream.get_length() > 1.0, label + " stream has usable duration")
			check(player.stream is AudioStreamMP3 if rainy else player.stream is AudioStreamWAV, label + " correct stream selected")
			check(player.playing and player.bus == &"SFX", label + " playing on SFX bus")
			check(is_equal_approx(player.volume_db, -12.0), label + " ambience level applied")
			check(player.finished.is_connected(player.play), label + " repeats after finishing")
			var finished_count := [0]
			player.finished.connect(func(): finished_count[0] += 1)
			player.seek(player.stream.get_length() - 0.08)
			await create_timer(0.5).timeout
			check(finished_count[0] > 0 and player.playing and player.get_playback_position() < 1.0, label + " naturally reaches end and restarts")
		city.queue_free()
		await process_frame
		check(not is_instance_valid(player), label + " stops when city is freed")
	print("AMBIENCE_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures:
		print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
