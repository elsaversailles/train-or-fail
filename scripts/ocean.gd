extends MeshInstance3D

@export var camera: Camera3D

# grid_step = Mesh Size / Subdivisions (e.g., 100 / 64 = 1.5625)
# Snapping to the vertex grid avoids visual swimming/jittering artifacts.
@export var grid_step: float = 1.5625

func _process(_delta: float) -> void:
	if not camera:
		camera = get_viewport().get_camera_3d()
		if not camera:
			return

	var cam_pos = camera.global_position
	global_position.x = round(cam_pos.x / grid_step) * grid_step
	global_position.z = round(cam_pos.z / grid_step) * grid_step
