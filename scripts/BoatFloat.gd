extends Node3D

@export_group("Vertical Bobbing")
## How far up and down the boat moves (in meters)
@export var bob_height: float = 0.2
## Speed of the up-and-down bobbing motion
@export var bob_speed: float = 1.6

@export_group("Wave Rocking")
## Side-to-side tilt in degrees (Roll)
@export var roll_degrees: float = 3.5
## Front-to-back tilt in degrees (Pitch)
@export var pitch_degrees: float = 2.0
## Speed of the rocking motion
@export var rock_speed: float = 1.2

var _initial_y: float = 0.0
var _initial_rot: Vector3 = Vector3.ZERO
var _time: float = 0.0

func _ready() -> void:
	_initial_y = position.y
	_initial_rot = rotation

func _process(delta: float) -> void:
	_time += delta

	# 1. Vertical heave (smooth up and down)
	position.y = _initial_y + sin(_time * bob_speed) * bob_height

	# 2. Side-to-side roll (Z axis) & front-to-back pitch (X axis)
	# Using slightly different speed multipliers (1.0 vs 0.75) keeps the motion organic
	var roll = deg_to_rad(sin(_time * rock_speed) * roll_degrees)
	var pitch = deg_to_rad(cos(_time * rock_speed * 0.75) * pitch_degrees)

	rotation.z = _initial_rot.z + roll
	rotation.x = _initial_rot.x + pitch
