extends Node3D

const WALK_ANIMATION := &"walking/walk"
const CAMERA_FOCUS := Vector3(0.0, 0.62, 0.0)
const CAMERA_RADIUS := 4.5
const ORBIT_SPEED := 1.4

@onready var _animation: AnimationPlayer = $Character/Player/AnimationPlayer
@onready var _camera: Camera3D = $Camera3D
@onready var _pause_button: Button = %PauseButton
@onready var _speed_slider: HSlider = %SpeedSlider
@onready var _speed_label: Label = %SpeedValue

var _playing := true
var _dragging := false
var _yaw := 0.45
var _pitch := 0.18


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_pause_button.pressed.connect(_toggle_playback)
	_speed_slider.value_changed.connect(_set_speed)
	%ResetButton.pressed.connect(_restart)
	%FrontButton.pressed.connect(_show_front)
	%SideButton.pressed.connect(_show_side)
	_set_speed(_speed_slider.value)
	_animation.play(WALK_ANIMATION)
	_update_camera()


func _process(delta: float) -> void:
	var horizontal := float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	var vertical := float(Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_DOWN))
	if not is_zero_approx(horizontal) or not is_zero_approx(vertical):
		_yaw += horizontal * ORBIT_SPEED * delta
		_pitch = clampf(_pitch + vertical * ORBIT_SPEED * delta, -0.05, 0.65)
		_update_camera()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * 0.008
		_pitch = clampf(_pitch + event.relative.y * 0.006, -0.05, 0.65)
		_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE:
				_toggle_playback()
				get_viewport().set_input_as_handled()
			KEY_R:
				_restart()
				get_viewport().set_input_as_handled()


func _toggle_playback() -> void:
	_playing = not _playing
	if _playing:
		_animation.play(WALK_ANIMATION)
	else:
		_animation.pause()
	_pause_button.text = "Pause" if _playing else "Play"


func _set_speed(value: float) -> void:
	_animation.speed_scale = value
	_speed_label.text = "%.2fx" % value


func _restart() -> void:
	_animation.play(WALK_ANIMATION)
	_animation.seek(0.0, true)
	if not _playing:
		_animation.pause()


func _show_front() -> void:
	_yaw = 0.0
	_pitch = 0.18
	_update_camera()


func _show_side() -> void:
	_yaw = PI / 2.0
	_pitch = 0.18
	_update_camera()


func _update_camera() -> void:
	_camera.position = CAMERA_FOCUS + Vector3(
		sin(_yaw) * cos(_pitch),
		sin(_pitch),
		cos(_yaw) * cos(_pitch)
	) * CAMERA_RADIUS
	_camera.look_at(CAMERA_FOCUS)
