extends Node
## Outside-world-only patrol; the character and its interaction body move together.

const WALK_LIBRARY := preload("res://animation/walk_animation.tres")
const WALK := &"outdoor/walk"
const IDLE := &"outdoor/idle"
const BLEND_TIME := 0.18

@export_node_path("Path3D") var patrol_path: NodePath
## Building outcome days in addition to the interaction script's story days.
@export var additional_story_days: Array[int] = []
@export_range(0.5, 5.0, 0.1) var walk_speed := 2.0
@export_range(0.0, 5.0, 0.1) var turnaround_pause := 1.2
@export var start_backwards := false

var _npc: Node3D
var _interaction_body: StaticBody3D
var _animation: AnimationPlayer
var _skeleton: Skeleton3D
var _path: Path3D
var _follower: PathFollow3D
var _home: Transform3D
var _direction := 1.0
var _wait_remaining := 0.0
var _story_locked := false
var _interacting := false
var _conversation_player: Node3D
var _player: Node3D
var _current_day := -1
var _walk_playback_speed := 1.0
var _active_animation: StringName
var _initialized := false


func _ready() -> void:
	_npc = get_parent() as Node3D
	_home = _npc.global_transform
	_interaction_body = _npc.get_node_or_null("StaticBody3D") as StaticBody3D
	_animation = _npc.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_skeleton = _npc.find_child("Skeleton3D", true, false) as Skeleton3D
	# Other root branches (including the authored paths) must enter the tree first.
	_setup.call_deferred()


func _setup() -> void:
	_path = get_node_or_null(patrol_path) as Path3D
	if _path == null or _path.curve == null or _path.curve.get_baked_length() < 0.1:
		push_warning("No usable sidewalk patrol for " + str(_npc.name))
		return
	if _animation == null or _skeleton == null:
		push_warning("No character rig for " + str(_npc.name))
		return
	_prepare_animations()
	_follower = PathFollow3D.new()
	_follower.name = "PatrolFollower"
	_follower.rotation_mode = PathFollow3D.ROTATION_NONE
	_follower.loop = false
	_path.add_child(_follower)
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_direction = -1.0 if start_backwards else 1.0
	_initialized = true
	_apply_day(int(SaveManager.current_save_data.get("current_day", 1)))


func _prepare_animations() -> void:
	# Some imports bake scale into their bones. Retarget translations per instance.
	var walk := WALK_LIBRARY.get_animation("walk").duplicate(true) as Animation
	var spine := _skeleton.find_bone("spine")
	var own_rest := _skeleton.get_bone_rest(spine).origin
	var reference_rest: Vector3 = walk.get_meta("reference_spine_position")
	var ratio := own_rest.y / reference_rest.y
	for track in walk.get_track_count():
		if walk.track_get_type(track) == Animation.TYPE_POSITION_3D:
			for key in walk.track_get_key_count(track):
				var value: Vector3 = walk.track_get_key_value(track, key)
				walk.track_set_key_value(track, key, own_rest + (value - reference_rest) * ratio)
	var idle := _animation.get_animation("idle").duplicate(true) as Animation
	var position_track := idle.add_track(Animation.TYPE_POSITION_3D)
	idle.track_set_path(position_track, NodePath("Skeleton3D:spine"))
	idle.position_track_insert_key(position_track, 0.0, own_rest)
	var library := AnimationLibrary.new()
	library.add_animation("walk", walk)
	library.add_animation("idle", idle)
	_animation.add_animation_library("outdoor", library)
	var authored_speed: float = walk.get_meta("reference_speed")
	_walk_playback_speed = walk_speed / (authored_speed * ratio * _skeleton.global_basis.get_scale().y)


func _is_story_day(day: int) -> bool:
	if day in additional_story_days:
		return true
	if _interaction_body:
		if "assigned_days" in _interaction_body and day in _interaction_body.assigned_days:
			return true
		if "assigned_day" in _interaction_body and day == _interaction_body.assigned_day:
			return true
		if "special_days" in _interaction_body and day in _interaction_body.special_days:
			return true
	return false


func _apply_day(day: int) -> void:
	_current_day = day
	_story_locked = _is_story_day(day)
	_wait_remaining = 0.0
	if _story_locked:
		_npc.global_transform = _home
		_play_animation(false)
	else:
		_follower.progress = _path.curve.get_closest_offset(_path.to_local(_home.origin))
		_npc.global_position = _follower.global_position
		_face_direction(_travel_direction(), 1.0)
		_play_animation(true)


func begin_interaction(player: Node3D) -> void:
	_interacting = true
	_conversation_player = player
	if _initialized:
		_play_animation(false)
	_face_conversation_player(1.0)


func end_interaction() -> void:
	_interacting = false
	_conversation_player = null
	# Finish facing the sidewalk before taking the first step again.
	_wait_remaining = maxf(_wait_remaining, 0.35)


func _physics_process(delta: float) -> void:
	if not _initialized:
		return
	var day := int(SaveManager.current_save_data.get("current_day", 1))
	if day != _current_day:
		_apply_day(day)
	if not _npc.is_visible_in_tree():
		_play_animation(false)
		return
	if _interacting:
		_play_animation(false)
		_face_conversation_player(1.0 - exp(-9.0 * delta))
		return
	if _story_locked:
		_play_animation(false)
		return
	var direction := _travel_direction()
	_face_direction(direction, 1.0 - exp(-9.0 * delta))
	if _wait_remaining > 0.0:
		_wait_remaining = maxf(0.0, _wait_remaining - delta)
		_play_animation(false)
		return
	# Yield to the player instead of moving an interaction collider through them.
	if _player_blocks_path(direction):
		_play_animation(false)
		return
	var length := _path.curve.get_baked_length()
	var next := _follower.progress + _direction * walk_speed * delta
	_follower.progress = clampf(next, 0.0, length)
	_npc.global_position = _follower.global_position
	if next <= 0.0 or next >= length:
		_direction *= -1.0
		_wait_remaining = turnaround_pause
		_play_animation(false)
	else:
		_play_animation(true)


func _travel_direction() -> Vector3:
	var ahead := clampf(_follower.progress + _direction * 0.75, 0.0, _path.curve.get_baked_length())
	var target := _path.to_global(_path.curve.sample_baked(ahead))
	var direction := target - _follower.global_position
	direction.y = 0.0
	return direction.normalized()


func _face_conversation_player(weight: float) -> void:
	if is_instance_valid(_conversation_player):
		_face_direction(_conversation_player.global_position - _npc.global_position, weight)


func _face_direction(direction: Vector3, weight: float) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var parent := _npc.get_parent_node_3d()
	if parent:
		direction = parent.global_basis.inverse() * direction
	# These character scenes face +Z. Changing yaw preserves their authored scale.
	_npc.rotation.y = lerp_angle(_npc.rotation.y, atan2(direction.x, direction.z), weight)


func _player_blocks_path(direction: Vector3) -> bool:
	if not is_instance_valid(_player):
		return false
	var offset := _player.global_position - _npc.global_position
	if absf(offset.y) > 5.0:
		return false
	offset.y = 0.0
	return offset.length_squared() < 9.0 and offset.dot(direction) > 0.25


func _play_animation(walking: bool) -> void:
	var target := WALK if walking else IDLE
	if _active_animation == target:
		return
	_active_animation = target
	_animation.play(target, BLEND_TIME, _walk_playback_speed if walking else 1.0)


func _exit_tree() -> void:
	if is_instance_valid(_follower):
		_follower.queue_free()
