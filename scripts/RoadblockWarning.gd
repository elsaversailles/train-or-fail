extends Area3D

const WARNING_TIMELINE := "res://Dialogic/Timelines/road_blocked.dtl"

var has_triggered: bool = false
var _player: Node3D = null

func _ready() -> void:
	set_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if has_triggered or not body.is_in_group("player"):
		return
	_player = body
	set_process(true)

func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_clear_pending_warning()

func _process(_delta: float) -> void:
	if has_triggered or not is_instance_valid(_player) or not overlaps_body(_player):
		_clear_pending_warning()
		return
	# Wait until gameplay resumes, and never replace a story conversation.
	if get_tree().paused or SceneTransition.is_transitioning or Dialogic.current_timeline != null:
		return
	if _player.get("is_paused") or _player.get("is_in_dialogue"):
		return
	if not is_visible_in_tree():
		return

	# One warning per roadblock row per map visit, even if the player lingers.
	has_triggered = true
	_clear_pending_warning()
	# The player controller already locks/restores input through Dialogic signals.
	Dialogic.start(WARNING_TIMELINE)

func _clear_pending_warning() -> void:
	_player = null
	set_process(false)
