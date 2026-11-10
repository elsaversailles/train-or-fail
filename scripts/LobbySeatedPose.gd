extends RefCounted
## Static seated pose for the shared applicant rig. The models face local +Z.


# Returns the hip center in the character root's local space for seat placement.
static func apply(character: Node3D) -> Vector3:
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_warning("No skeleton for lobby visitor: " + str(character.name))
		return Vector3.ZERO
	var animation := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation:
		# Start from the existing relaxed pose, including shoulders and hands.
		if animation.has_animation("idle"):
			animation.play("idle")
			animation.advance(0.0)
		animation.stop(true)
		animation.active = false
	var neutral: Array[Basis] = []
	for bone in skeleton.get_bone_count():
		neutral.append(skeleton.get_bone_global_pose(bone).basis.orthonormalized())
	for side in ["L", "R"]:
		var outward := 1.0 if side == "L" else -1.0
		# Keep thighs above the cushion. The taller visitors extend their feet
		# forward so their shins clear the seat and their soles stay above the floor.
		_aim(skeleton, neutral, "thigh." + side, Vector3(0.04 * outward, 0.0, 1.0))
		_aim(skeleton, neutral, "shin." + side, Vector3(0.0, -0.78, 0.625))
		var foot := skeleton.find_bone("foot." + side)
		if foot >= 0:
			_set_global_basis(skeleton, foot, neutral[foot])
		# Relax the upper arms and rest both hands above the thighs.
		_aim(skeleton, neutral, "upper_arm." + side, Vector3(0.08 * outward, -1.0, 0.18))
		_aim(skeleton, neutral, "forearm." + side, Vector3(-0.06 * outward, -0.35, 1.0))
		_aim(skeleton, neutral, "hand." + side, Vector3(-0.06 * outward, -0.25, 1.0))
	var left_hip := skeleton.find_bone("thigh.L")
	var right_hip := skeleton.find_bone("thigh.R")
	if left_hip < 0 or right_hip < 0:
		return Vector3.ZERO
	var hip := (skeleton.get_bone_global_pose(left_hip).origin + skeleton.get_bone_global_pose(right_hip).origin) * 0.5
	return character.to_local(skeleton.to_global(hip))


static func _aim(skeleton: Skeleton3D, neutral: Array[Basis], bone_name: String, direction: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return
	# Bone +Y points to its child. Align in skeleton space so import scales and
	# different local rest orientations do not change the resulting pose.
	var alignment := Quaternion(neutral[bone].y.normalized(), direction.normalized())
	_set_global_basis(skeleton, bone, Basis(alignment) * neutral[bone])


static func _set_global_basis(skeleton: Skeleton3D, bone: int, target: Basis) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var local := target
	if parent >= 0:
		local = skeleton.get_bone_global_pose(parent).basis.inverse() * target
	skeleton.set_bone_pose_rotation(bone, local.orthonormalized().get_rotation_quaternion())
