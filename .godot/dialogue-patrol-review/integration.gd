extends Node

class TestPlayer extends Node3D:
	var is_paused := false
	var is_in_dialogue := false

class FastBubble extends Node3D:
	signal finished_displaying
	var spoken := ""
	func display_text(text: String) -> void:
		spoken = text
		visible = true
		_emit_finished.call_deferred()
	func _emit_finished() -> void:
		finished_displaying.emit()

const CASES := [
	{"name": "Grandpa", "model": "M/grandpa", "script": "Grandpa", "days": [1], "extra": [], "generic": ["grandpa_generic_1"]},
	{"name": "Assistant", "model": "F/trisha_aquino", "script": "PartnerNPC", "days": [1], "extra": [], "generic": ["assistant_generic_1"]},
	{"name": "Mark", "model": "M/mark_krazy", "script": "Mark", "days": [2, 4], "extra": [], "generic": ["mark_generic_1"]},
	{"name": "Cashier", "model": "M/angelo", "script": "PartnerNPC", "days": [2, 4], "extra": [], "generic": ["cashier_generic_1"]},
	{"name": "Clara", "model": "F/nurse_clara_garcia", "script": "NurseClara", "days": [7], "extra": [8], "generic": ["clara_generic_1"]},
	{"name": "Supplier", "model": "M/briar_galima", "script": "PartnerNPC", "days": [7], "extra": [8], "generic": ["supplier_generic_1"]},
	{"name": "Jericho", "model": "M/prof__jericho_santur", "script": "jericho", "days": [8], "extra": [9], "generic": ["jericho_generic_1"]},
	{"name": "Joice", "model": "F/michele_garcia", "script": "PartnerNPC", "days": [8], "extra": [9], "generic": ["joice_generic_1"]},
]

var failures: Array[String] = []
var assertions := 0
var fixtures: Array[Dictionary] = []
var test_player: TestPlayer
var story_checks := 0
var generic_checks := 0
var floor_checks := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _signature(animation: Animation) -> Array:
	var signature: Array = []
	for track in animation.get_track_count():
		var values: Array = [animation.track_get_type(track), str(animation.track_get_path(track))]
		for key in animation.track_get_key_count(track):
			values.append([animation.track_get_key_time(track, key), animation.track_get_key_value(track, key)])
		signature.append(values)
	return signature

func _fixture(data: Dictionary, index: int) -> Dictionary:
	var container := Node3D.new()
	container.name = data.name + "Fixture"
	container.position.z = index * 100.0
	var path := Path3D.new()
	path.name = "Sidewalk"
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3(-30, 0, 0))
	path.curve.add_point(Vector3(30, 0, 0))
	container.add_child(path)
	var character := load("res://models3d/characters/%s.tscn" % data.model).instantiate() as Node3D
	character.name = data.name
	character.scale = Vector3.ONE * 2.7
	character.rotation.y = 0.4
	container.add_child(character)
	var body := AnimatableBody3D.new()
	body.name = "StaticBody3D"
	body.sync_to_physics = false
	body.position = Vector3(0, 0.01, 0)
	body.scale = Vector3.ONE * 1.1
	body.set_script(load("res://scripts/dialogue/%s.gd" % data.script))
	if data.script == "PartnerNPC":
		body.special_days.assign(data.days)
		body.model_needs_flip = true
	body.generic_timelines.assign(data.generic)
	character.add_child(body)
	var collision := CollisionShape3D.new()
	collision.position.y = 0.8527577
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 2.309082
	collision.shape = capsule
	body.add_child(collision)
	var bubble := FastBubble.new()
	bubble.name = "NPCDialogueBox"
	character.add_child(bubble)
	if data.name == "Mark":
		body.mark_bubble = bubble
	var patrol := Node.new()
	patrol.name = "OutdoorNpcPatrol"
	patrol.set_script(load("res://scripts/OutdoorNpcPatrol.gd"))
	patrol.patrol_path = NodePath("../../Sidewalk")
	patrol.additional_story_days.assign(data.extra)
	character.add_child(patrol)
	add_child(container)
	var animation := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return {"container": container, "character": character, "body": body, "patrol": patrol, "animation": animation, "bubble": bubble, "data": data, "home": character.global_transform}

func _step(fixture: Dictionary, seconds: float) -> void:
	var frames := maxi(1, ceili(seconds * 60.0))
	for frame in frames:
		fixture.patrol._physics_process(seconds / frames)
		fixture.animation.advance(seconds / frames)

func _run() -> void:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data.current_day = 3
	var source_walk := load("res://animation/walk_animation.tres").get_animation("walk") as Animation
	var source_idle := load("res://animation/idle_animation.res").get_animation("idle") as Animation
	var original_walk := _signature(source_walk)
	var original_idle := _signature(source_idle)
	test_player = TestPlayer.new()
	test_player.name = "Player"
	add_child(test_player)
	test_player.add_to_group("player")
	test_player.global_position = Vector3(-100, 0, -100)
	for index in CASES.size():
		fixtures.append(_fixture(CASES[index], index))
	await get_tree().process_frame
	await get_tree().process_frame
	for fixture in fixtures:
		fixture.patrol.set_physics_process(false)
		check(fixture.patrol._initialized, fixture.data.name + " initializes")
		check(is_equal_approx(fixture.patrol._path.curve.get_baked_length(), 60.0), fixture.data.name + " has 60m world route")
		_test_schedule(fixture)
		_test_animation_retarget(fixture, source_walk)
	await _test_native_physics_colliders()
	for fixture in fixtures:
		await _test_generic_interaction(fixture)
	await _test_story_interactions()
	await _test_extra_story_generic()
	await _test_mark_bubble()
	check(_signature(source_walk) == original_walk, "Shared source walk resource was not mutated")
	check(_signature(source_idle) == original_idle, "Shared source idle resource was not mutated")
	for fixture in fixtures:
		fixture.container.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("PATROL_INTEGRATION assertions=", assertions, " story_cases=", story_checks, " generic_cases=", generic_checks, " floor_frames=", floor_checks, " failures=", failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_schedule(fixture: Dictionary) -> void:
	var name: String = fixture.data.name
	for day in fixture.data.days + fixture.data.extra:
		SaveManager.current_save_data.current_day = 3
		_step(fixture, 0.5)
		var before: Vector3 = fixture.character.global_position
		_step(fixture, 1.0)
		check(fixture.character.global_position.distance_to(before) > 1.9, name + " patrols on quiet day")
		check(fixture.animation.current_animation == "outdoor/walk", name + " uses walking clip on quiet day")
		SaveManager.current_save_data.current_day = day
		_step(fixture, 0.6)
		check(fixture.patrol._story_locked, name + " recognizes story day " + str(day))
		check(fixture.character.global_transform.is_equal_approx(fixture.home), name + " stays at authored story transform on day " + str(day))
		check(fixture.animation.current_animation == "outdoor/idle", name + " idles on story day " + str(day))
		var spine: int = fixture.patrol._skeleton.find_bone("spine")
		check(fixture.patrol._skeleton.get_bone_pose_position(spine).is_equal_approx(fixture.patrol._skeleton.get_bone_rest(spine).origin), name + " resets spine translation on story day " + str(day))
		story_checks += 1

func _test_animation_retarget(fixture: Dictionary, source: Animation) -> void:
	SaveManager.current_save_data.current_day = 3
	_step(fixture, 0.5)
	var skeleton: Skeleton3D = fixture.patrol._skeleton
	var animation: AnimationPlayer = fixture.animation
	var own_walk := animation.get_animation("outdoor/walk")
	var spine := skeleton.find_bone("spine")
	var own_rest := skeleton.get_bone_rest(spine).origin
	var reference_rest: Vector3 = source.get_meta("reference_spine_position")
	var ratio := own_rest.y / reference_rest.y
	var source_track := source.find_track(NodePath("Skeleton3D:spine"), Animation.TYPE_POSITION_3D)
	var own_track := own_walk.find_track(NodePath("Skeleton3D:spine"), Animation.TYPE_POSITION_3D)
	check(own_walk != source, fixture.data.name + " owns a private retargeted walk")
	for sample in 5:
		var time := source.length * sample / 4.0
		var expected := own_rest + (source.position_track_interpolate(source_track, time) - reference_rest) * ratio
		check(own_walk.position_track_interpolate(own_track, time).is_equal_approx(expected), fixture.data.name + " retargets spine key " + str(sample))
	animation.play("outdoor/walk", 0.0, fixture.patrol._walk_playback_speed)
	var lowest := INF
	var highest_support := -INF
	for sample in 97:
		animation.seek(source.length * float(sample % 96) / 96.0, true)
		skeleton.force_update_all_bone_transforms()
		var support := INF
		for side in ["L", "R"]:
			for marker in ["heel.02.", "toe."]:
				var point := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(marker + side)).origin
				var height: float = point.y - fixture.character.global_position.y
				lowest = minf(lowest, height)
				support = minf(support, height)
		highest_support = maxf(highest_support, support)
		floor_checks += 1
	check(lowest >= -0.005, fixture.data.name + " walk soles avoid ground clipping: " + str(lowest))
	check(highest_support <= 0.005, fixture.data.name + " walk keeps a planted foot: " + str(highest_support))
	print("RETARGET ", fixture.data.name, " ratio=", ratio, " native_scale=", skeleton.global_basis.get_scale().y, " min_sole=", lowest, " max_support=", highest_support, " playback_speed=", fixture.patrol._walk_playback_speed)
	fixture.patrol.begin_interaction(test_player)
	_step(fixture, 0.4)
	check(skeleton.get_bone_pose_position(spine).is_equal_approx(own_rest), fixture.data.name + " talking idle restores native spine height")
	fixture.patrol.end_interaction()
	_step(fixture, 0.4)

func _test_native_physics_colliders() -> void:
	SaveManager.current_save_data.current_day = 3
	test_player.global_position = Vector3(-100, 0, -100)
	for fixture in fixtures:
		fixture.patrol._apply_day(3)
		fixture.patrol.set_physics_process(true)
	for frame in 12:
		await get_tree().physics_frame
	await get_tree().process_frame
	for fixture in fixtures:
		fixture.patrol.set_physics_process(false)
		var physical: Transform3D = PhysicsServer3D.body_get_state(fixture.body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM)
		check(fixture.character.global_position.distance_to(fixture.home.origin) > 0.1, fixture.data.name + " moves during native physics ticks")
		check(physical.origin.distance_to(fixture.body.global_position) < 0.0001, fixture.data.name + " physics collider follows moving parent")
		var capsule_center: Vector3 = fixture.body.global_transform * Vector3(0, 0.8527577, 0)
		var ray := PhysicsRayQueryParameters3D.create(capsule_center + Vector3(0, 0, -6), capsule_center + Vector3(0, 0, 6), 1)
		var hit: Dictionary = fixture.character.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == fixture.body, fixture.data.name + " moving collider is still ray-interactable")

func _test_generic_interaction(fixture: Dictionary) -> void:
	SaveManager.current_save_data.current_day = 3
	fixture.patrol._apply_day(3)
	_step(fixture, 0.5)
	test_player.global_position = fixture.character.global_position + Vector3(5, 0, 8)
	var stopped_at: Vector3 = fixture.character.global_position
	fixture.body.interact()
	await get_tree().process_frame
	check(fixture.body.is_talking, fixture.data.name + " starts real generic conversation")
	check(Dialogic.current_timeline != null, fixture.data.name + " starts actual Dialogic timeline")
	check(fixture.patrol._interacting, fixture.data.name + " interaction hook holds patrol")
	_step(fixture, 0.6)
	check(fixture.character.global_position.is_equal_approx(stopped_at), fixture.data.name + " stays stopped during conversation")
	check(fixture.animation.current_animation == "outdoor/idle", fixture.data.name + " plays idle during conversation")
	var to_player: Vector3 = test_player.global_position - fixture.character.global_position
	to_player.y = 0
	check(fixture.character.global_basis.z.normalized().dot(to_player.normalized()) > 0.999, fixture.data.name + " faces player with +Z forward")
	var other: Dictionary = fixtures[1] if fixture.data.name == "Grandpa" else fixtures[0]
	other.body.interact()
	check(not other.body.is_talking, "Other NPC cannot interrupt " + fixture.data.name + " dialogue")
	await Dialogic.end_timeline(true)
	await get_tree().process_frame
	check(not fixture.body.is_talking and not fixture.patrol._interacting, fixture.data.name + " releases patrol after real Dialogic end")
	_step(fixture, 0.6)
	check(fixture.character.global_position.distance_to(stopped_at) > 0.1, fixture.data.name + " resumes walking from stopped spot")
	check(fixture.animation.current_animation == "outdoor/walk", fixture.data.name + " resumes walking clip")
	generic_checks += 1

func _test_story_interactions() -> void:
	for index in [0, 2, 4, 6]:
		var fixture: Dictionary = fixtures[index]
		var day: int = fixture.data.days[0]
		SaveManager.current_save_data.current_day = day
		_step(fixture, 0.3)
		fixture.body.can_talk = true
		test_player.global_position = fixture.character.global_position + Vector3(5, 0, 8)
		fixture.body.interact()
		await get_tree().process_frame
		check(Dialogic.current_timeline != null, fixture.data.name + " story conversation still works")
		await Dialogic.end_timeline(true)
		await get_tree().process_frame
		_step(fixture, 0.7)
		check(not fixture.patrol._interacting, fixture.data.name + " releases interaction after story")
		check(fixture.character.global_position.is_equal_approx(fixture.home.origin), fixture.data.name + " stays at story location after dialogue")
		check(fixture.animation.current_animation == "outdoor/idle", fixture.data.name + " remains idle after story dialogue")

func _test_mark_bubble() -> void:
	var fixture: Dictionary = fixtures[2]
	SaveManager.current_save_data.current_day = 4
	_step(fixture, 0.3)
	test_player.global_position = fixture.character.global_position + Vector3(5, 0, 8)
	fixture.body.interact()
	await get_tree().process_frame
	check(fixture.body.is_talking and fixture.patrol._interacting, "Mark day4 locks patrol before Dialogic starts")
	check(fixture.bubble.spoken.contains("accept my ID"), "Mark day4 keeps overhead bubble speech")
	check(Dialogic.current_timeline == null, "Mark overhead bubble precedes Dialogic")
	_step(fixture, 0.8)
	check(fixture.character.global_position.is_equal_approx(fixture.home.origin), "Mark remains home during overhead speech")
	Engine.time_scale = 30.0
	await get_tree().create_timer(3.2).timeout
	Engine.time_scale = 1.0
	check(Dialogic.current_timeline != null, "Mark day4 starts Dialogic after bubble pause")
	await Dialogic.end_timeline(true)
	await get_tree().process_frame
	_step(fixture, 0.7)
	check(not fixture.body.is_talking and not fixture.patrol._interacting, "Mark day4 releases conversation lock")
	check(fixture.character.global_position.is_equal_approx(fixture.home.origin), "Mark day4 remains at authored story position")
	check(fixture.animation.current_animation == "outdoor/idle", "Mark day4 remains idle after dialogue")

func _test_extra_story_generic() -> void:
	for index in [4, 5, 6, 7]:
		var fixture: Dictionary = fixtures[index]
		SaveManager.current_save_data.current_day = fixture.data.extra[0]
		_step(fixture, 0.3)
		test_player.global_position = fixture.character.global_position + Vector3(5, 0, 8)
		fixture.body.interact()
		await get_tree().process_frame
		check(Dialogic.current_timeline != null, fixture.data.name + " remains interactable on building outcome day")
		check(fixture.patrol._interacting, fixture.data.name + " holds interaction on building outcome day")
		await Dialogic.end_timeline(true)
		await get_tree().process_frame
		_step(fixture, 0.7)
		check(not fixture.patrol._interacting, fixture.data.name + " releases building-day interaction")
		check(fixture.character.global_position.is_equal_approx(fixture.home.origin), fixture.data.name + " stays home after building-day generic dialogue")
		check(fixture.animation.current_animation == "outdoor/idle", fixture.data.name + " stays idle after building-day generic dialogue")
