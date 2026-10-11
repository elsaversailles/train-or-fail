extends Path3D

@export var speed := 25            # meters per second
@export var wheelbase := 3.65       # rear axle to front axle, in meters
@export var turn_smoothing := 10.0  # higher = snappier turning

@onready var jeepney: Node3D = $Jeepney

var dist := 0.0

func _process(delta: float) -> void:
	var length := curve.get_baked_length()
	dist = fposmod(dist + speed * delta, length)

	# rear axle on the path, front axle one wheelbase ahead
	var rear := curve.sample_baked(dist, true)
	var front := curve.sample_baked(fposmod(dist + wheelbase, length), true)

	# body sits halfway between the two axles
	jeepney.position = (rear + front) * 0.5

	# face from the rear axle toward the front axle (-Z is forward)
	var dir := front - rear
	dir.y = 0.0
	if dir.length() > 0.001:
		var target_yaw := atan2(-dir.x, -dir.z)
		var t := 1.0 - exp(-turn_smoothing * delta)
		jeepney.rotation.y = lerp_angle(jeepney.rotation.y, target_yaw, t)

	jeepney.speed = speed           # keeps the wheel spin matched
