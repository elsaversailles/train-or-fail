extends WorldEnvironment
class_name OutdoorGraphics

const STOCK_ENVIRONMENT_SCENE = preload("res://scene/world_environment_stock.tscn")

var _enhanced_environment: Environment
var _stock_environment: Environment

func _ready() -> void:
	_enhanced_environment = environment.duplicate(true)
	var stock_node := STOCK_ENVIRONMENT_SCENE.instantiate() as WorldEnvironment
	_stock_environment = stock_node.environment.duplicate(true)
	stock_node.free()
	SettingsManager.graphics_settings_changed.connect(_apply_graphics)
	_apply_graphics()

func get_enhanced_environment() -> Environment:
	return _enhanced_environment

func set_enhanced_environment(new_environment: Environment) -> void:
	_enhanced_environment = new_environment
	_apply_graphics()

func _apply_graphics() -> void:
	if _enhanced_environment == null or _stock_environment == null:
		return
	# The editor or a command-line override can still start in Compatibility.
	# Enable Forward+ effects only in a renderer that can display them.
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	_enhanced_environment.sdfgi_enabled = forward_plus
	_enhanced_environment.volumetric_fog_enabled = forward_plus
	_enhanced_environment.ssr_enabled = forward_plus
	_enhanced_environment.fog_enabled = not forward_plus
	_enhanced_environment.fog_density = 0.7
	_stock_environment.fog_enabled = true
	_stock_environment.fog_density = 0.7
	var distance := SettingsManager.get_render_distance_meters()
	for candidate in [_enhanced_environment, _stock_environment]:
		match SettingsManager.render_distance:
			SettingsManager.RENDER_DISTANCE_NEAR:
				candidate.fog_depth_begin = 55.0
				candidate.fog_depth_end = 110.0
			SettingsManager.RENDER_DISTANCE_ULTRA_FAR:
				candidate.fog_depth_begin = 300.0
				candidate.fog_depth_end = 520.0
			_:
				candidate.fog_depth_begin = 110.0
				candidate.fog_depth_end = 220.0
	if not forward_plus:
		_enhanced_environment.fog_depth_begin = 40.0
		_enhanced_environment.fog_depth_end = 170.0
	environment = _enhanced_environment if SettingsManager.enhanced_lighting else _stock_environment
	var sun := get_node_or_null("../Sun") as DirectionalLight3D
	if sun:
		sun.visible = SettingsManager.enhanced_lighting
	# The player camera may not have entered the tree yet on the first call.
	call_deferred("_apply_camera_distance", distance)

func _apply_camera_distance(distance: float) -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	for node in scene_root.find_children("*", "Camera3D", true, false):
		var camera := node as Camera3D
		if camera.is_inside_tree() and camera.get_viewport() == get_viewport():
			camera.far = distance
