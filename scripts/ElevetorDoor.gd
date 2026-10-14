extends Area3D

@export var supervisor: Node3D
@export var warning_timeline: String = "elevator_warning"

var player_in_area: bool = false
var is_checking: bool = false

func _ready() -> void:
	if not supervisor:
		supervisor = get_tree().get_first_node_in_group("supervisor")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		if "current_zone_prompt" in body:
			var current_day = int(SaveManager.current_save_data.get("current_day", 1))
			
			# If on mandatory days and supervisor has not been talked to
			if current_day in [1, 4, 7] and supervisor and not supervisor.has_completed_dialogue:
				body.current_zone_prompt = "Talk to supervisor first"
			else:
				body.current_zone_prompt = "Press E to Enter"

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		if "current_zone_prompt" in body:
			body.current_zone_prompt = ""

func _unhandled_input(event: InputEvent) -> void:
	if player_in_area and event.is_action_pressed("interact") and not is_checking:
		var current_day = int(SaveManager.current_save_data.get("current_day", 1))

		# Mandatory dialogue days: Days 1, 4, and 7
		if current_day in [1, 4, 7]:
			if not supervisor:
				supervisor = get_tree().get_first_node_in_group("supervisor")
				
			if supervisor and not supervisor.has_completed_dialogue:
				trigger_supervisor_warning()
				return

		# Enter elevator
		player_in_area = false
		$CollisionShape3D.set_deferred("disabled", true)
		
		var player = get_tree().get_first_node_in_group("player")
		if player and "current_zone_prompt" in player:
			player.current_zone_prompt = ""
		
		await get_tree().create_timer(1.0).timeout
		SceneTransition.change_scene("res://scene/elevator.tscn")

func trigger_supervisor_warning() -> void:
	is_checking = true
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		if "is_in_dialogue" in player:
			player.is_in_dialogue = true

		if player.has_method("turn_camera_towards") and supervisor:
			var target_pos = supervisor.global_position + Vector3(0, 1.4, 0)
			var tween = player.turn_camera_towards(target_pos, 0.6)
			await tween.finished

	Dialogic.start(warning_timeline)
	await Dialogic.timeline_ended

	if player and "is_in_dialogue" in player:
		player.is_in_dialogue = false

	is_checking = false
