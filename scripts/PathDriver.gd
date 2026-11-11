extends Path3D

@export var cruise_speed := 16.0     # normal driving speed (m/s)
@export var acceleration := 12.0     # how fast it speeds up again
@export var braking := 45.0          # how fast it stops
@export var wheelbase := 3.65
@export var turn_smoothing := 10.0
@export var horn_delay := 1.0

@onready var jeepney: Node3D = $Jeepney
@onready var front_trigger: Area3D = $Jeepney/FrontTrigger

var speed := 0.0
var dist := 0.0
var player_in_front := false
var stopped_time := 0.0
var horn_player: AudioStreamPlayer

func _ready() -> void:
	front_trigger.body_entered.connect(_on_front_body_entered)
	front_trigger.body_exited.connect(_on_front_body_exited)
	_setup_horn()

func _setup_horn() -> void:
	horn_player = AudioStreamPlayer.new()
	horn_player.name = "JeepneyHorn"
	horn_player.bus = &"SFX"
	horn_player.stream = load("res://assets/music/sfx/beep jeep.mp3") as AudioStream
	add_child(horn_player)
	horn_player.finished.connect(horn_player.play)

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

	# handle horn delay when fully stopped, and stop horn when moving
	if player_in_front and is_zero_approx(speed):
		stopped_time += delta
		if stopped_time >= horn_delay and not horn_player.playing:
			horn_player.play()
	else:
		stopped_time = 0.0
		if horn_player.playing:
			horn_player.stop()

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
