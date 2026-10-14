extends Path3D

@export var cruise_speed := 16.0     # normal driving speed (m/s)
@export var acceleration := 12.0     # how fast it speeds up again
@export var braking := 40.0         # how fast it stops
@export var wheelbase := 3.65
@export var turn_smoothing := 10.0

@onready var jeepney: Node3D = $Jeepney
@onready var front_trigger: Area3D = $Jeepney/FrontTrigger

var speed := 0.0
var dist := 0.0
var player_in_front := false

func _ready() -> void:
	front_trigger.body_entered.connect(_on_front_body_entered)
	front_trigger.body_exited.connect(_on_front_body_exited)

func _on_front_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_front = true

func _on_front_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_front = false

func _physics_process(delta: float) -> void:
	# brake while the player is in front, otherwise drive
	var target := 0.0 if player_in_front else cruise_speed
	var rate := braking if player_in_front else acceleration
	speed = move_toward(speed, target, rate * delta)

	var length := curve.get_baked_length()
	dist = fposmod(dist + speed * delta, length)

	var rear := curve.sample_baked(dist, true)
	var front := curve.sample_baked(fposmod(dist + wheelbase, length), true)
	jeepney.position = (rear + front) * 0.5

	var dir := front - rear
	dir.y = 0.0
	if dir.length() > 0.001:
		var target_yaw := atan2(-dir.x, -dir.z)
		var t := 1.0 - exp(-turn_smoothing * delta)
		jeepney.rotation.y = lerp_angle(jeepney.rotation.y, target_yaw, t)

	jeepney.speed = speed           # wheels slow down and stop with the jeepney
