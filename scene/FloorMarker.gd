extends Node3D

@onready var disc_mesh: MeshInstance3D = $DiscMesh
@onready var ground_light: OmniLight3D = $GroundLight

@export var pulse_speed: float = 3.0
@export var min_energy: float = 0.8
@export var max_energy: float = 2.2

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta * pulse_speed
	var pulse = (sin(time_passed) + 1.0) * 0.5 # Normalizes sine wave to 0.0 - 1.0
	
	# Pulse the real light
	if ground_light:
		ground_light.light_energy = lerp(min_energy, max_energy, pulse)
	
	# Pulse the emissive mesh material
	if disc_mesh:
		var mat = disc_mesh.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = lerp(1.5, 4.0, pulse)
