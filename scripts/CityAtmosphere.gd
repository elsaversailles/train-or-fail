extends Node3D

const RAIN_SHADER = preload("res://shader/rain_streak.gdshader")
const BIRD_SHADER = preload("res://shader/bird.gdshader")
const WET_ROAD_SHADER = preload("res://shader/wet_road.gdshader")
const BIRD_COUNT := 10
const BIRD_UPDATE_INTERVAL := 0.05
const SKY_UPDATE_INTERVAL := 0.5
const STREETLIGHT_POSITIONS := [
	Vector3(6.0, 5.0, -5.0), Vector3(-17.0, 5.0, -5.0),
	Vector3(-41.0, 5.0, -5.0), Vector3(-64.0, 5.0, -6.0),
	Vector3(-74.0, 5.0, 5.0), Vector3(-95.0, 5.0, 38.0),
	Vector3(-105.0, 5.0, 47.0), Vector3(-95.0, 5.0, 94.0),
	Vector3(-105.0, 5.0, 103.0), Vector3(-181.0, 5.0, 110.0),
	Vector3(-201.0, 5.0, 125.0), Vector3(-211.0, 5.0, 145.0),
]

@export var player_path: NodePath = ^"../Player"
@export var environment_path: NodePath = ^"../WorldEnvironment"
@export var sun_path: NodePath = ^"../Sun"
@export_range(600.0, 7200.0, 60.0) var sun_crossing_seconds := 1800.0

var _player: Node3D
var _environment: Environment
var _sky_material: ShaderMaterial
var _sun: DirectionalLight3D
var _rain: GPUParticles3D
var _flock: MultiMesh
var _flock_timer := 0.0
var _flight_time := 0.0
var _sky_time := 0.0
var _sky_timer := 0.0
var _rainy := false
var _streetlights: Array[OmniLight3D] = []

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_sun = get_node_or_null(sun_path) as DirectionalLight3D
	var world_environment := get_node_or_null(environment_path) as OutdoorGraphics
	if world_environment == null or _player == null or _sun == null:
		return

	# Scene resources are shared with the boat and dock: use a private weather copy.
	var environment := world_environment.get_enhanced_environment().duplicate(true)
	_environment = environment
	if environment.sky:
		environment.sky = environment.sky.duplicate(true)
		if environment.sky.sky_material:
			environment.sky.sky_material = environment.sky.sky_material.duplicate(true)
			_sky_material = environment.sky.sky_material as ShaderMaterial

	var day: int = SaveManager.current_save_data.get("current_day", 1)
	_rainy = SaveManager.get_weather_rain_for_day(day)
	_configure_wet_road()
	_configure_lamp_glow()
	_configure_post_process()
	_configure_lighting(environment)
	world_environment.set_enhanced_environment(environment)
	_make_streetlights()
	SettingsManager.graphics_settings_changed.connect(_update_streetlight_visibility)
	_update_sky()
	_make_birds()
	if _rainy:
		_make_rain()

func _configure_wet_road() -> void:
	var map := get_node_or_null("../Map")
	if map == null:
		return
	var road := map.find_child("New Road", true, false) as MeshInstance3D
	if road == null or road.mesh == null:
		return
	for surface in road.mesh.get_surface_count():
		var original := road.get_active_material(surface) as BaseMaterial3D
		if original == null or original.albedo_texture == null:
			continue
		var material := ShaderMaterial.new()
		material.shader = WET_ROAD_SHADER
		material.set_shader_parameter("road_texture", original.albedo_texture)
		material.set_shader_parameter("albedo_tint", original.albedo_color)
		material.set_shader_parameter("wetness", (0.42 if _rainy else 0.1) if surface == 6 else (0.72 if _rainy else 0.16))
		road.set_surface_override_material(surface, material)

func _configure_post_process() -> void:
	var overlay := get_node_or_null("../CityPostProcess/ColorRect") as ColorRect
	if overlay == null:
		return
	var material := overlay.material as ShaderMaterial
	if material:
		material.set_shader_parameter("rain_mix", 1.0 if _rainy else 0.0)

func _configure_lamp_glow() -> void:
	var map := get_node_or_null("../Map")
	if map == null:
		return
	for mesh in map.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var original := instance.get_active_material(surface) as StandardMaterial3D
			if original == null or original.resource_name != "Light Lamp":
				continue
			var material := original.duplicate() as StandardMaterial3D
			material.emission_enabled = true
			material.emission_energy_multiplier = 1.4
			instance.set_surface_override_material(surface, material)

func _configure_lighting(environment: Environment) -> void:
	# Static city geometry contributes to SDFGI; the moving sun updates its bounce.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.75
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.ssao_enabled = true
	environment.ssao_radius = 1.2
	environment.ssao_intensity = 1.25
	environment.volumetric_fog_density = 0.042 if _rainy else 0.028
	environment.volumetric_fog_albedo = Color(0.67, 0.73, 0.8) if _rainy else Color(0.91, 0.72, 0.57)
	if _rainy:
		_sky_material.set_shader_parameter("zenith_color", Color(0.28, 0.36, 0.45))
		_sky_material.set_shader_parameter("horizon_color", Color(0.57, 0.62, 0.68))
		_sky_material.set_shader_parameter("sunset_color", Color(0.72, 0.52, 0.44))
		_sky_material.set_shader_parameter("cloud_light_color", Color(0.74, 0.78, 0.81))
		_sky_material.set_shader_parameter("cloud_shadow_color", Color(0.36, 0.43, 0.49))
		_sky_material.set_shader_parameter("cloud_threshold", 0.43)
		_sky_material.set_shader_parameter("cloud_opacity", 0.9)
		_sky_material.set_shader_parameter("haze_amount", 0.35)
		_sky_material.set_shader_parameter("sun_cloud_transmission", 0.18)

func _update_sky() -> void:
	if _sun == null or _sky_material == null:
		return
	# +X is east, -X is west. The sun holds near sunset at the end of a long day.
	var progress: float = minf(0.80 + _sky_time / sun_crossing_seconds * 0.13, 0.93)
	var angle: float = PI * progress
	var to_sun := Vector3(cos(angle), sin(angle) * 0.86, -0.28).normalized()
	_sun.basis = Basis.looking_at(-to_sun, Vector3.UP)
	var warmth: float = pow(absf(progress * 2.0 - 1.0), 2.0)
	var daylight: float = sin(angle)
	_sun.light_color = Color(1.0, 0.87, 0.72).lerp(Color(1.0, 0.48, 0.25), warmth) if not _rainy else Color(0.74, 0.81, 0.88)
	_sun.light_energy = (0.58 + daylight * 0.5) * (0.55 if _rainy else 1.0)
	_environment.ambient_light_energy = (0.29 + daylight * 0.18) * (0.8 if _rainy else 1.0)
	_environment.fog_light_color = Color(0.58, 0.65, 0.73).lerp(Color(0.78, 0.58, 0.45), warmth * 0.6) if not _rainy else Color(0.47, 0.54, 0.62)
	for light in _streetlights:
		light.light_energy = 2.1 + (1.0 - daylight) * 1.1
	_update_streetlight_visibility()
	# Tiny uniform changes at 2 Hz avoid per-frame sky cubemap rebuilds.
	_sky_material.set_shader_parameter("cloud_offset", Vector2(_sky_time * 0.0006, _sky_time * 0.00008))

func _make_streetlights() -> void:
	var group := Node3D.new()
	group.name = "Streetlights"
	add_child(group)
	for position in STREETLIGHT_POSITIONS:
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = Color(1.0, 0.72, 0.43)
		light.omni_range = 18.0
		light.omni_attenuation = 1.35
		light.light_volumetric_fog_energy = 0.0
		light.light_bake_mode = Light3D.BAKE_STATIC
		light.shadow_enabled = false
		group.add_child(light)
		_streetlights.append(light)

func _update_streetlight_visibility() -> void:
	for light in _streetlights:
		light.visible = SettingsManager.enhanced_lighting
	# Keep the warm sun in the low-quality preset, without expensive shadows.
	if _sun:
		_sun.visible = true
		_sun.shadow_enabled = SettingsManager.enhanced_lighting

func _make_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 360
	_rain.lifetime = 0.75
	_rain.explosiveness = 0.0
	_rain.local_coords = true
	_rain.visibility_aabb = AABB(Vector3(-22.0, -14.0, -22.0), Vector3(44.0, 32.0, 44.0))

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(19.0, 1.0, 19.0)
	material.direction = Vector3(0.12, -1.0, 0.03)
	material.spread = 4.0
	material.initial_velocity_min = 19.0
	material.initial_velocity_max = 26.0
	material.gravity = Vector3(0.0, -9.8, 0.0)
	_rain.process_material = material

	var drop := QuadMesh.new()
	drop.size = Vector2(0.026, 0.62)
	var drop_material := ShaderMaterial.new()
	drop_material.shader = RAIN_SHADER
	drop.material = drop_material
	_rain.draw_pass_1 = drop
	add_child(_rain)
	_rain.emitting = true

func _make_birds() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two angular wings and a short body, all one low-poly surface.
	_add_triangle(surface, Vector3(-1.25, 0.0, -0.2), Vector3(-0.13, 0.0, 0.0), Vector3(-0.45, 0.0, 0.43), 1.0)
	_add_triangle(surface, Vector3(1.25, 0.0, -0.2), Vector3(0.45, 0.0, 0.43), Vector3(0.13, 0.0, 0.0), 1.0)
	_add_triangle(surface, Vector3(0.0, 0.12, -0.55), Vector3(-0.15, 0.0, 0.25), Vector3(0.15, 0.0, 0.25), 0.0)
	var mesh := surface.commit()
	var bird_material := ShaderMaterial.new()
	bird_material.shader = BIRD_SHADER
	mesh.surface_set_material(0, bird_material)

	_flock = MultiMesh.new()
	_flock.transform_format = MultiMesh.TRANSFORM_3D
	_flock.use_custom_data = true
	_flock.mesh = mesh
	_flock.instance_count = BIRD_COUNT
	for i in BIRD_COUNT:
		_flock.set_instance_custom_data(i, Color(float(i) / float(BIRD_COUNT), 0.0, 0.0, 1.0))
	var instance := MultiMeshInstance3D.new()
	instance.name = "BirdFlock"
	instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	instance.multimesh = _flock
	instance.custom_aabb = AABB(Vector3(-270.0, 8.0, -85.0), Vector3(300.0, 60.0, 370.0))
	add_child(instance)
	_update_birds()

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tip: float) -> void:
	for vertex in [a, b, c]:
		surface.set_uv(Vector2(tip if absf(vertex.x) > 0.4 else 0.0, 0.0))
		surface.add_vertex(vertex)

func _process(delta: float) -> void:
	if _player == null:
		return
	if _rain != null:
		_rain.global_position = _player.global_position + Vector3(0.0, 12.0, 0.0)
	_flight_time += delta
	_sky_time += delta
	_sky_timer += delta
	if _sky_timer >= SKY_UPDATE_INTERVAL and SettingsManager.enhanced_lighting:
		_sky_timer = 0.0
		_update_sky()
	_flock_timer += delta
	if _flock != null and _flock_timer >= BIRD_UPDATE_INTERVAL:
		_flock_timer = 0.0
		_update_birds()

func _update_birds() -> void:
	for i in BIRD_COUNT:
		var group := i / 3
		var phase := float(i) * 2.39996
		var speed := 0.12 + float(group) * 0.025
		var angle := _flight_time * speed + phase
		var radius := 28.0 + float(i % 3) * 8.0
		var center := Vector3(-165.0 + float(group) * 22.0, 25.0, 80.0 + float(group) * 30.0)
		var position := center + Vector3(cos(angle) * radius, sin(_flight_time * 0.9 + phase) * 2.0 + float(i % 3) * 3.0, sin(angle) * radius)
		var forward := Vector3(-sin(angle), 0.0, cos(angle))
		var basis := Basis.looking_at(forward, Vector3.UP)
		_flock.set_instance_transform(i, Transform3D(basis, position))
