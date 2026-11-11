extends SkeletonModifier3D
## Holds the umbrella after the idle/walk animation has posed the character.

const UMBRELLA := preload("res://assets/umbrella/umbrella.glb")
# The imported handle is above the model origin; this is its straight grip.
const HANDLE_GRIP := Vector3(0.0, 1.23, 0.0)
const REFERENCE_HEAD_HEIGHT := 1.503

var _rig: Skeleton3D
var _upper_arm := -1
var _forearm := -1
var _hand := -1
var _neutral: Dictionary = {}
var _umbrella: Node3D
var _rig_scale := 1.0


func _ready() -> void:
	_rig = get_skeleton()
	if _rig == null:
		return
	_upper_arm = _rig.find_bone("upper_arm.R")
	_forearm = _rig.find_bone("forearm.R")
	_hand = _rig.find_bone("hand.R")
	var head := _rig.find_bone("spine.006")
	if _upper_arm < 0 or _forearm < 0 or _hand < 0 or head < 0:
		active = false
		return
	# Models use different import scales. Size the prop in their bone space.
	_rig_scale = _rig.get_bone_global_rest(head).origin.y / REFERENCE_HEAD_HEIGHT
	for bone in [_upper_arm, _forearm, _hand]:
		_neutral[bone] = _rig.get_bone_global_rest(bone).basis.orthonormalized()
	_umbrella = UMBRELLA.instantiate() as Node3D
	_umbrella.name = "Umbrella"
	add_child(_umbrella)


func _process_modification() -> void:
	if _umbrella == null or not _rig.is_visible_in_tree():
		return
	# Leave the other arm, torso and legs animated while keeping this hand up.
	_aim(_upper_arm, Vector3(-0.12, -0.65, 0.75))
	_aim(_forearm, Vector3(0.1, 0.8, 0.6))
	_aim(_hand, Vector3(0.0, 0.95, 0.3))
	var hand_pose := _rig.get_bone_global_pose(_hand)
	var palm := hand_pose * Vector3(0.0, 0.055 * _rig_scale, 0.0)
	var umbrella_scale := 0.65 * _rig_scale
	# Follow the posed palm, but keep the canopy upright instead of swinging it.
	_umbrella.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * umbrella_scale), palm - HANDLE_GRIP * umbrella_scale)


func _aim(bone: int, direction: Vector3) -> void:
	var neutral: Basis = _neutral[bone]
	var alignment := Quaternion(neutral.y.normalized(), direction.normalized())
	var target := Basis(alignment) * neutral
	var parent := _rig.get_bone_parent(bone)
	var local := _rig.get_bone_global_pose(parent).basis.inverse() * target
	_rig.set_bone_pose_rotation(bone, local.orthonormalized().get_rotation_quaternion())
