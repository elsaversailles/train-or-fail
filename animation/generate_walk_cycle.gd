extends SceneTree
## Rebuild the editable AnimationLibrary with Godot's --headless --script option.
## The walk is in place, faces +Z, and is authored for the shared character rig.

const SOURCE := "res://models3d/characters/M/adrian_santos.tscn"
const OUTPUT := "res://animation/walk_animation.tres"
const DURATION := 1.08
const SAMPLES := 48
const STRIDE := 0.58
const STANCE := 0.60

var skeleton: Skeleton3D
var rest: Array[Transform3D] = []
var neutral: Array[Quaternion] = []
var neutral_global: Array[Transform3D] = []
var local_pose: Array[Transform3D] = []
var global_pose: Array[Transform3D] = []


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	var character := load(SOURCE).instantiate() as Node3D
	root.add_child(character)
	skeleton = character.get_node("Player/Skeleton3D")
	var player: AnimationPlayer = character.get_node("Player/AnimationPlayer")
	player.stop()
	var idle := player.get_animation("idle")
	for bone in skeleton.get_bone_count():
		rest.append(skeleton.get_bone_rest(bone))
		var track := idle.find_track(NodePath("Skeleton3D:" + skeleton.get_bone_name(bone)), Animation.TYPE_ROTATION_3D)
		neutral.append(idle.rotation_track_interpolate(track, 0.0) if track >= 0 else rest[bone].basis.get_rotation_quaternion())
		local_pose.append(Transform3D(Basis(neutral[bone]), rest[bone].origin))
		global_pose.append(Transform3D.IDENTITY)
	_update_globals()
	neutral_global.assign(global_pose)
	var walk := Animation.new()
	walk.resource_name = "walk"
	walk.length = DURATION
	walk.loop_mode = Animation.LOOP_LINEAR
	walk.set_meta("reference_spine_position", rest[skeleton.find_bone("spine")].origin)
	walk.set_meta("reference_speed", 2.0 * STRIDE / (STANCE * DURATION))
	for bone in skeleton.get_bone_count():
		var track := walk.add_track(Animation.TYPE_ROTATION_3D)
		walk.track_set_path(track, NodePath("Skeleton3D:" + skeleton.get_bone_name(bone)))
	var position_track := walk.add_track(Animation.TYPE_POSITION_3D)
	walk.track_set_path(position_track, NodePath("Skeleton3D:spine"))
	for sample in SAMPLES + 1:
		# Reuse phase zero at the endpoint for an exactly seamless loop.
		var phase := float(sample % SAMPLES) / SAMPLES
		_pose(phase)
		var time := float(sample) * DURATION / SAMPLES
		for bone in skeleton.get_bone_count():
			walk.rotation_track_insert_key(bone, time, local_pose[bone].basis.get_rotation_quaternion().normalized())
		walk.position_track_insert_key(position_track, time, local_pose[0].origin)
	# Static bones need just one key; keep both endpoints on moving tracks.
	for track in skeleton.get_bone_count():
		var first: Quaternion = walk.track_get_key_value(track, 0)
		var constant := true
		for key in walk.track_get_key_count(track):
			var value: Quaternion = walk.track_get_key_value(track, key)
			if first.angle_to(value) > 0.00001:
				constant = false
				break
		if constant:
			for key in range(walk.track_get_key_count(track) - 1, 0, -1):
				walk.track_remove_key(track, key)
	var library := AnimationLibrary.new()
	library.add_animation("walk", walk)
	var result := ResourceSaver.save(library, OUTPUT)
	print("Walk cycle saved: ", OUTPUT, " (", walk.get_track_count(), " tracks, ", DURATION, " seconds), result=", result)
	character.free()
	quit(result)


func _update_globals() -> void:
	for bone in skeleton.get_bone_count():
		var parent := skeleton.get_bone_parent(bone)
		global_pose[bone] = global_pose[parent] * local_pose[bone] if parent >= 0 else local_pose[bone]


func _set_global_rotation(bone: int, rotation: Basis) -> void:
	var parent := skeleton.get_bone_parent(bone)
	local_pose[bone].basis = (global_pose[parent].basis.inverse() * rotation).orthonormalized() if parent >= 0 else rotation
	_update_globals()


func _pose(phase: float) -> void:
	for bone in skeleton.get_bone_count():
		local_pose[bone] = Transform3D(Basis(neutral[bone]), rest[bone].origin)
	var cycle := TAU * phase
	local_pose[0].origin += Vector3(0.035 * sin(cycle), -0.115 - 0.025 * cos(2.0 * cycle), 0.0)
	local_pose[0].basis = Basis(Vector3.UP, -0.035 * cos(cycle)) * Basis(Vector3.RIGHT, 0.025) * Basis(neutral[0])
	_update_globals()
	# The chest counters the hips while the head stays relatively steady.
	var chest := skeleton.find_bone("spine.002")
	local_pose[chest].basis = Basis(Vector3.UP, 0.065 * cos(cycle)) * Basis(neutral[chest])
	_update_globals()
	var head := skeleton.find_bone("spine.006")
	local_pose[head].basis = Basis(Vector3.UP, -0.025 * cos(cycle)) * Basis(neutral[head])
	_update_globals()
	for side in ["L", "R"]:
		var leg_phase := fposmod(phase + (0.5 if side == "R" else 0.0), 1.0)
		_leg(side, leg_phase)
		_arm(side, cycle)


func _leg(side: String, phase: float) -> void:
	var thigh := skeleton.find_bone("thigh." + side)
	var shin := skeleton.find_bone("shin." + side)
	var foot := skeleton.find_bone("foot." + side)
	var toe := skeleton.find_bone("toe." + side)
	var heel := skeleton.find_bone("heel.02." + side)
	var target := neutral_global[foot].origin
	var pitch: float
	if phase < STANCE:
		var contact := phase / STANCE
		target.z += lerpf(STRIDE, -STRIDE, contact)
		# Heel contact settles into a flat sole, then rolls onto the toe.
		pitch = deg_to_rad(-8.0) * (1.0 - smoothstep(0.0, 0.15, contact))
		pitch += deg_to_rad(20.0) * smoothstep(0.68, 1.0, contact)
	else:
		var swing := (phase - STANCE) / (1.0 - STANCE)
		# Cubic trajectory matches the backward stance velocity at both ends.
		var tangent := -2.0 * STRIDE * (1.0 - STANCE) / STANCE
		var z := (2.0 * swing * swing * swing - 3.0 * swing * swing + 1.0) * -STRIDE
		z += (swing * swing * swing - 2.0 * swing * swing + swing) * tangent
		z += (-2.0 * swing * swing * swing + 3.0 * swing * swing) * STRIDE
		z += (swing * swing * swing - swing * swing) * tangent
		target.z += z
		target.y += 0.27 * pow(sin(PI * swing), 2.0)
		pitch = deg_to_rad(lerpf(20.0, -8.0, smoothstep(0.0, 1.0, swing)))
	var foot_basis := Basis(Vector3.RIGHT, pitch) * neutral_global[foot].basis
	# Keep the lowest sole marker on the floor as the foot rolls.
	var toe_offset := foot_basis * rest[toe].origin
	var heel_offset := foot_basis * rest[heel].origin
	target.y += -neutral_global[foot].origin.y - minf(toe_offset.y, heel_offset.y)
	var hip := global_pose[thigh].origin
	var upper_length := rest[shin].origin.length()
	var lower_length := rest[foot].origin.length()
	var to_ankle := target - hip
	var distance := clampf(to_ankle.length(), 0.01, (upper_length + lower_length) * 0.9999)
	var direction := to_ankle.normalized()
	var pole := (Vector3.BACK - direction * Vector3.BACK.dot(direction)).normalized()
	var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
	var bend := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var knee := hip + direction * along + pole * bend
	_point_bone(thigh, knee - hip)
	_point_bone(shin, target - global_pose[shin].origin)
	_set_global_rotation(foot, foot_basis)
	# Ease the toe out of its planted bend after push-off.
	if pitch > 0.0:
		var release := smoothstep(0.0, 0.35, (phase - STANCE) / (1.0 - STANCE)) if phase >= STANCE else 0.0
		_set_global_rotation(toe, Basis(Vector3.RIGHT, pitch * release) * neutral_global[toe].basis)


func _point_bone(bone: int, direction: Vector3) -> void:
	var original := neutral_global[bone].basis.orthonormalized()
	var alignment := Quaternion(original.y.normalized(), direction.normalized())
	_set_global_rotation(bone, Basis(alignment) * original)


func _arm(side: String, cycle: float) -> void:
	var upper := skeleton.find_bone("upper_arm." + side)
	var forearm := skeleton.find_bone("forearm." + side)
	var sign_side := 1.0 if side == "L" else -1.0
	var swing := 0.24 * cos(cycle) * sign_side
	# Preserve the relaxed arms from the existing idle, with opposite leg swing.
	var shoulder := skeleton.get_bone_parent(upper)
	var torso_delta := global_pose[shoulder].basis * neutral_global[shoulder].basis.inverse()
	_set_global_rotation(upper, Basis(Vector3.RIGHT, swing) * torso_delta * neutral_global[upper].basis)
	local_pose[forearm].basis = Basis(neutral[forearm]) * Basis(Vector3.RIGHT, -0.055 * (1.0 - cos(cycle) * sign_side))
	_update_globals()
