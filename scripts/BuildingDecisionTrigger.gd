extends Area3D

# Enter the exact ID from applicant_database.gd: "tita_elena", "nurse_clara", or "jericho_santur"
@export var special_npc_id: String = "tita_elena"

# Dialogic timeline names to play when walking near the building
@export var open_timeline: String = "bakery_open"
@export var closed_timeline: String = "bakery_closed"

# Drag the building's CautionTape (Sprite3D) and outside NPCs here
@export var caution_tape: Sprite3D
@export var shop_npcs: Array[Node3D] = []

# FOR TESTING ONLY: Type "sus" or "legit" here to test without playing the office shift.
# Leave this blank ("") for the actual game
@export var debug_test_verdict: String = ""

# ---------------------------------------------------------------------------
# CUTSCENE CAMERA SETTINGS
# ---------------------------------------------------------------------------
@export_group("Cutscene Camera")

## Turn off to skip the camera move and just play the dialogue.
@export var use_cutscene_camera: bool = true

## Drop a Marker3D here. The camera moves to this marker's position and
## faces the direction the marker faces (its -Z axis, same as a normal camera).
## Place it at least 13 meters in front of the building to see the whole thing.
@export var camera_anchor: Marker3D

## Field of view during the cutscene. Raise it to see more of the building.
@export_range(30.0, 120.0, 1.0) var camera_fov: float = 70.0

## Seconds for the camera to move to / from the building.
@export var transition_time: float = 1.0

## Freeze the player's movement during the cutscene.
@export var freeze_player: bool = true

var has_triggered: bool = false


func _ready() -> void:
	# Auto-connect the signal if it wasn't connected in the editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	update_building_visuals()


func _get_current_verdict() -> String:
	var verdict: String = SaveManager.get_special_decision(special_npc_id)
	# If SaveManager has no decision yet (e.g., testing with F6), use debug_test_verdict
	if verdict == "" and debug_test_verdict != "":
		return debug_test_verdict
	return verdict


func update_building_visuals() -> void:
	var verdict: String = _get_current_verdict()
	var is_closed: bool = (verdict == "sus")

	# Show caution tape only if the player rejected ("sus") this NPC
	if caution_tape:
		caution_tape.visible = is_closed

	# Hide outside NPCs if the shop is closed
	if is_closed:
		for npc in shop_npcs:
			if is_instance_valid(npc):
				npc.visible = false
				for collider in npc.find_children("*", "CollisionShape3D", true, false):
					collider.set_deferred("disabled", true)


func _on_body_entered(body: Node3D) -> void:
	print("Something touched building trigger (", name, "): ", body.name)

	if body.is_in_group("player") and not has_triggered:
		var verdict: String = _get_current_verdict()
		print("Player entered trigger for ", special_npc_id, " | Verdict is: '", verdict, "'")

		# Only trigger if the player has already evaluated this NPC (or set debug_test_verdict)
		if verdict == "legit":
			has_triggered = true
			await _play_cutscene(open_timeline, body)
			queue_free()

		elif verdict == "sus":
			has_triggered = true
			await _play_cutscene(closed_timeline, body)
			queue_free()


# ---------------------------------------------------------------------------
# CUTSCENE
# ---------------------------------------------------------------------------
func _play_cutscene(timeline_name: String, player: Node3D) -> void:
	var original_cam: Camera3D = get_viewport().get_camera_3d()
	var cutscene_cam: Camera3D = null

	if freeze_player:
		_set_player_frozen(player, true)

	# Warn if the marker is missing, then fall back to just playing the dialogue
	if use_cutscene_camera and not is_instance_valid(camera_anchor):
		push_warning("BuildingTrigger '%s': no Camera Anchor (Marker3D) assigned. Skipping camera move." % name)

	# Move the camera to the Marker3D
	if use_cutscene_camera and is_instance_valid(camera_anchor) and original_cam:
		cutscene_cam = Camera3D.new()
		get_tree().current_scene.add_child(cutscene_cam)
		cutscene_cam.global_transform = original_cam.global_transform
		cutscene_cam.fov = original_cam.fov
		cutscene_cam.make_current()

		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel(true)
		tween.tween_property(cutscene_cam, "global_transform", camera_anchor.global_transform, transition_time)
		tween.tween_property(cutscene_cam, "fov", camera_fov, transition_time)
		await tween.finished

	# Play the dialogue
	Dialogic.start(timeline_name)
	await Dialogic.timeline_ended

	# Return the camera to the player
	if cutscene_cam and is_instance_valid(cutscene_cam):
		if original_cam and is_instance_valid(original_cam):
			var back: Tween = create_tween()
			back.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			back.set_parallel(true)
			back.tween_property(cutscene_cam, "global_transform", original_cam.global_transform, transition_time)
			back.tween_property(cutscene_cam, "fov", original_cam.fov, transition_time)
			await back.finished
			original_cam.make_current()
		cutscene_cam.queue_free()

	if freeze_player:
		_set_player_frozen(player, false)


func _set_player_frozen(player: Node3D, frozen: bool) -> void:
	player.set_process(not frozen)
	player.set_physics_process(not frozen)
	player.set_process_input(not frozen)
	player.set_process_unhandled_input(not frozen)
