extends Node3D

@export var wheel_radius := 0.43   # same as WHEEL_R in the Blender script
@export var speed := 8.0           # meters per second

var wheels: Array[Node3D] = []

func _ready() -> void:
	for n in ["Wheel_F_L", "Wheel_F_R", "Wheel_R_L", "Wheel_R_R"]:
		var w := find_child(n, true, false) as Node3D
		if w:
			wheels.append(w)
		else:
			push_warning("Wheel node not found: " + n)

func _process(delta: float) -> void:
	var spin := speed / wheel_radius * delta   # radians this frame
	for w in wheels:
		w.rotate_x(spin)
