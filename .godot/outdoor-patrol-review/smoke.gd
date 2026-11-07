extends Node

const NPC_PATHS := [
	"FraudDetection/Grandpa", "FraudDetection/Assistant",
	"FraudDetection/Mark Krazy", "FraudDetection/Cashier",
	"CreditScoring/Nurse Clara", "CreditScoring/Supplier",
	"CreditScoring/Prof_ Jericho Santur", "CreditScoring/Joice",
]
const LOCKS := [[1], [1], [2, 4], [2, 4], [7, 8], [7, 8], [8, 9], [8, 9]]

var level: Node3D
var player: Node3D
var npcs: Array[Node3D] = []
var patrols: Array[Node] = []
var failures: Array[String] = []
var checks := 0


func _ready() -> void:
	call_deferred("_run")


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error(description)


func far_player() -> void:
	player.global_position = Vector3(10000.0, 100.0, 10000.0)


func day(number: int) -> void:
	SaveManager.current_save_data["current_day"] = number
	for patrol in patrols:
		patrol._apply_day(number)


func steps(count: int, delta := 0.1) -> void:
	for step in count:
		for patrol in patrols:
			patrol._physics_process(delta)


func flush_physics() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame


func _run() -> void:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = 3
	SaveManager.current_save_data["special_decisions"] = {
		"tita_elena": "legit", "nurse_clara": "legit", "jericho_santur": "legit"
	}
	level = load("res://scene/outside_world.tscn").instantiate() as Node3D
	level.set_script(null)
	level.get_node("CityAtmosphere").set_script(null)
	level.get_node("Track").set_script(null)
	for area in level.find_children("*", "Area3D", true, false):
		area.monitoring = false
		area.monitorable = false
	player = level.get_node("Player")
	player.set_physics_process(false)
	player.set_process(false)
	get_tree().root.add_child(level)
	get_tree().current_scene = level
	far_player()
	await get_tree().process_frame
	await get_tree().process_frame
	await flush_physics()
	for path in NPC_PATHS:
		var npc := level.get_node(path) as Node3D
		var patrol := npc.get_node("OutdoorNpcPatrol")
		patrol.set_physics_process(false)
		npcs.append(npc)
		patrols.append(patrol)
		check(patrol._initialized, path + " initializes")
		check(patrol._path is Path3D, path + " has authored Path3D")
		var length: float = patrol._path.curve.get_baked_length()
		check(length >= 55.0 and length <= 65.0, path + " patrol length about 60m: " + str(length))
		check(patrol._follower is PathFollow3D, path + " follows native path")
		check(patrol._animation.has_animation("outdoor/walk"), path + " has private walk")
		check(patrol._animation.has_animation("outdoor/idle"), path + " has private idle")
		var body: AnimatableBody3D = npc.get_node("StaticBody3D")
		check(not body.sync_to_physics, path + " collider uses parent movement")
		print("PATROL_INITIALIZED ", path, " length=", length, " speed=", patrol._walk_playback_speed)
	var tita := level.get_node("Tita Elena") as Node3D
	var tita_home := tita.global_transform
	var tita_animation: AnimationPlayer = tita.find_child("AnimationPlayer", true, false)
	check(not tita.has_node("OutdoorNpcPatrol"), "Tita has no patrol")
	check(tita_animation.current_animation == "idle", "Tita retains autoplay idle")
	day(3)
	var quiet_start: Array[Vector3] = []
	for npc in npcs:
		quiet_start.append(npc.global_position)
	steps(20)
	for index in npcs.size():
		check(npcs[index].global_position.distance_to(quiet_start[index]) > 3.5, NPC_PATHS[index] + " walks on quiet day")
		check(patrols[index]._animation.current_animation == "outdoor/walk", NPC_PATHS[index] + " plays walk")
	check(tita.global_transform.is_equal_approx(tita_home), "Tita stays fixed while others walk")
	for number in [1, 2, 4, 7, 8, 9]:
		day(number)
		var positions: Array[Vector3] = []
		for npc in npcs:
			positions.append(npc.global_position)
		steps(8)
		for index in npcs.size():
			var locked: bool = number in LOCKS[index]
			check(patrols[index]._story_locked == locked, NPC_PATHS[index] + " correct day " + str(number) + " lock")
			if locked:
				check(npcs[index].global_position.is_equal_approx(patrols[index]._home.origin), NPC_PATHS[index] + " remains at story spot day " + str(number))
				check(patrols[index]._animation.current_animation == "outdoor/idle", NPC_PATHS[index] + " idles on story day " + str(number))
			else:
				check(npcs[index].global_position.distance_to(positions[index]) > 1.2, NPC_PATHS[index] + " still walks on another NPC day " + str(number))
		print("STORY_DAY_CHECKED ", number)
	day(3)
	var reversals: Array[int] = []
	var largest_step: Array[float] = []
	for index in patrols.size():
		reversals.append(0)
		largest_step.append(0.0)
	for step in 800:
		for index in patrols.size():
			var patrol = patrols[index]
			var before: Vector3 = npcs[index].global_position
			var old_direction: float = patrol._direction
			patrol._physics_process(0.1)
			var displacement := npcs[index].global_position.distance_to(before)
			largest_step[index] = maxf(largest_step[index], displacement)
			check(displacement <= 0.35, NPC_PATHS[index] + " no teleport at step " + str(step) + ": " + str(displacement))
			if patrol._direction != old_direction:
				reversals[index] += 1
	for index in patrols.size():
		check(reversals[index] >= 2, NPC_PATHS[index] + " reverses repeatedly: " + str(reversals[index]))
	print("ENDPOINT_REVERSALS ", reversals, " MAX_0.1_SEC_STEP ", largest_step)
	day(3)
	for index in patrols.size():
		var patrol = patrols[index]
		var npc := npcs[index]
		var before := npc.global_position
		var scale_before := npc.scale
		player.global_position = before + Vector3(7.0, 0.0, 7.0)
		patrol.begin_interaction(player)
		for frame in 10:
			patrol._physics_process(0.1)
		check(npc.global_position.is_equal_approx(before), NPC_PATHS[index] + " stops for interaction")
		check(patrol._animation.current_animation == "outdoor/idle", NPC_PATHS[index] + " idles for interaction")
		var toward := player.global_position - npc.global_position
		toward.y = 0.0
		check(npc.global_basis.z.normalized().dot(toward.normalized()) > 0.999, NPC_PATHS[index] + " faces player with +Z")
		check(npc.scale.is_equal_approx(scale_before), NPC_PATHS[index] + " preserves scale when turning")
		far_player()
		patrol.end_interaction()
		for frame in 12:
			patrol._physics_process(0.1)
		check(npc.global_position.distance_to(before) > 1.0, NPC_PATHS[index] + " resumes after interaction")
		check(patrol._animation.current_animation == "outdoor/walk", NPC_PATHS[index] + " resumes walk animation")
		var direction: Vector3 = patrol._travel_direction()
		player.global_position = npc.global_position + direction * 2.5
		before = npc.global_position
		patrol._physics_process(0.1)
		check(npc.global_position.is_equal_approx(before), NPC_PATHS[index] + " yields to player")
		check(patrol._animation.current_animation == "outdoor/idle", NPC_PATHS[index] + " idles when yielding")
		far_player()
		npc.hide()
		for frame in 10:
			patrol._physics_process(0.1)
		check(npc.global_position.is_equal_approx(before), NPC_PATHS[index] + " stops while hidden")
		npc.show()
	print("INTERACTION_YIELD_HIDE_CHECKED")
	# Let the real physics server receive the moved transforms, then raycast them.
	day(3)
	steps(60)
	await flush_physics()
	for index in npcs.size():
		var body: AnimatableBody3D = npcs[index].get_node("StaticBody3D")
		var state: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM)
		check(state.origin.distance_to(body.global_position) < 0.001, NPC_PATHS[index] + " physics collider tracks visible root")
		var old_layer := body.collision_layer
		body.collision_layer = 1 << 19
		await flush_physics()
		var shape: CollisionShape3D = body.get_node("CollisionShape3D")
		var center := shape.global_position
		var query := PhysicsRayQueryParameters3D.create(center + Vector3(15.0, 0.0, 0.0), center - Vector3(15.0, 0.0, 0.0), 1 << 19)
		var hit := level.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.get("collider") == body, NPC_PATHS[index] + " ray hits moved interaction body")
		body.collision_layer = old_layer
	print("NATIVE_COLLIDERS_CHECKED")
	for setup in [
		["BakeryDecisionTrigger", "tita_elena", ["Tita Elena"], 3],
		["HospitalDecisionTrigger", "nurse_clara", ["CreditScoring/Nurse Clara", "CreditScoring/Supplier"], 8],
		["DealershipDecisionTrigger", "jericho_santur", ["CreditScoring/Prof_ Jericho Santur", "CreditScoring/Joice"], 9],
	]:
		var trigger = level.get_node(setup[0])
		day(10)
		SaveManager.current_save_data["special_decisions"][setup[1]] = "sus"
		trigger.update_building_visuals()
		await get_tree().process_frame
		for path in setup[2]:
			var npc := level.get_node(path) as Node3D
			check(not npc.visible, path + " hidden by suspicious building outcome")
			for shape in npc.find_children("*", "CollisionShape3D", true, false):
				check(shape.disabled, path + " collider disabled for closure")
			var patrol = npc.get_node_or_null("OutdoorNpcPatrol")
			if patrol:
				var before := npc.global_position
				for frame in 10:
					patrol._physics_process(0.1)
				check(npc.global_position.is_equal_approx(before), path + " closure stops patrol even on later quiet day")
		SaveManager.current_save_data["special_decisions"][setup[1]] = "legit"
		trigger.update_building_visuals()
		await get_tree().process_frame
		for path in setup[2]:
			var npc := level.get_node(path) as Node3D
			check(npc.visible, path + " visible for legitimate outcome")
			for shape in npc.find_children("*", "CollisionShape3D", true, false):
				check(not shape.disabled, path + " collider enabled for open shop")
		print("BUILDING_VISUALS_CHECKED ", setup[0])
	check(tita.global_transform.is_equal_approx(tita_home), "Tita remains fixed throughout all days/outcomes")
	check(tita_animation.current_animation == "idle", "Tita idle survives all checks")
	print("OUTDOOR_PATROL_SMOKE checks=", checks, " failures=", failures)
	level.free()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
