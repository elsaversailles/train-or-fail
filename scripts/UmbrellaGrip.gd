extends RefCounted
## The shared NPC rig has no finger bones. Curl only the holding hand's mesh,
## on a private instance, so dry-weather characters keep their original hands.

const KNUCKLE := 0.035
const CURL_RADIUS := 0.024
const GRIP_CENTER := Vector3(0.0, KNUCKLE, -CURL_RADIUS)


static func apply(rig: Skeleton3D, hand: int, rig_scale: float) -> void:
	for child in rig.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.skin == null or instance.mesh == null:
			continue
		var bind := _find_hand_bind(instance.skin, rig.get_bone_name(hand), hand)
		if bind < 0:
			continue
		var source := instance.mesh
		var to_hand := instance.skin.get_bind_pose(bind)
		var from_hand := to_hand.affine_inverse()
		var surfaces: Array[Array] = []
		var changed := false
		for surface in source.get_surface_count():
			var arrays := source.surface_get_arrays(surface).duplicate(true)
			_subdivide_fingers(arrays, bind, to_hand, rig_scale)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			var influences := bones.size() / vertices.size()
			for vertex in vertices.size():
				var weight := 0.0
				for influence in influences:
					var index := vertex * influences + influence
					if bones[index] == bind:
						weight += weights[index]
				if weight < 0.5:
					continue
				var point := (to_hand * vertices[vertex]) / rig_scale
				if point.y <= KNUCKLE:
					continue
				var angle := (point.y - KNUCKLE) / CURL_RADIUS
				var radius := CURL_RADIUS + point.z
				var curled := Vector3(point.x, KNUCKLE + radius * sin(angle), -CURL_RADIUS + radius * cos(angle))
				vertices[vertex] = vertices[vertex].lerp(from_hand * (curled * rig_scale), weight)
				# Transform shading with the curl, not just the vertex positions.
				var jacobian := Basis(Vector3.RIGHT, Vector3(0.0, radius / CURL_RADIUS * cos(angle), -radius / CURL_RADIUS * sin(angle)), Vector3(0.0, sin(angle), cos(angle)))
				var deformation := from_hand.basis * jacobian * to_hand.basis
				if not normals.is_empty():
					var bent_normal := (deformation.inverse().transposed() * normals[vertex]).normalized()
					normals[vertex] = normals[vertex].lerp(bent_normal, weight).normalized()
				if not tangents.is_empty():
					var tangent := Vector3(tangents[vertex * 4], tangents[vertex * 4 + 1], tangents[vertex * 4 + 2])
					tangent = tangent.lerp((deformation * tangent).normalized(), weight).normalized()
					tangents[vertex * 4] = tangent.x
					tangents[vertex * 4 + 1] = tangent.y
					tangents[vertex * 4 + 2] = tangent.z
				changed = true
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TANGENT] = tangents
			surfaces.append(arrays)
		if not changed:
			continue
		var gripped := ArrayMesh.new()
		for surface in surfaces.size():
			gripped.add_surface_from_arrays(source.surface_get_primitive_type(surface), surfaces[surface])
			gripped.surface_set_material(surface, source.surface_get_material(surface))
		instance.mesh = gripped


static func _hand_weight(arrays: Array, vertex: int, bind: int) -> float:
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var influences := bones.size() / vertices.size()
	var result := 0.0
	for slot in influences:
		if bones[vertex * influences + slot] == bind:
			result += weights[vertex * influences + slot]
	return result


static func _subdivide_fingers(arrays: Array, bind: int, to_hand: Transform3D, rig_scale: float) -> void:
	# The low-poly fingers have only a base and tip. Add rings along their length
	# before curling, so long triangles and the outline shell follow the grip.
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var result := PackedInt32Array()
	for triangle in range(0, indices.size(), 3):
		var polygon: Array[int] = [indices[triangle], indices[triangle + 1], indices[triangle + 2]]
		var is_hand := false
		for vertex in polygon:
			if _hand_weight(arrays, vertex, bind) >= 0.5 and (to_hand * arrays[Mesh.ARRAY_VERTEX][vertex]).y / rig_scale > KNUCKLE:
				is_hand = true
		if not is_hand:
			result.append_array(PackedInt32Array(polygon))
			continue
		var polygons: Array[Array] = [polygon]
		for cut in range(7):
			var height := KNUCKLE + float(cut) * 0.01
			var pieces: Array[Array] = []
			for piece in polygons:
				var lower: Array[int] = []
				var upper: Array[int] = []
				for corner in piece.size():
					var a: int = piece[corner]
					var b: int = piece[(corner + 1) % piece.size()]
					var a_y: float = (to_hand * arrays[Mesh.ARRAY_VERTEX][a]).y / rig_scale - height
					var b_y: float = (to_hand * arrays[Mesh.ARRAY_VERTEX][b]).y / rig_scale - height
					if a_y <= 0.000001:
						lower.append(a)
					if a_y >= -0.000001:
						upper.append(a)
					if (a_y < -0.000001 and b_y > 0.000001) or (a_y > 0.000001 and b_y < -0.000001):
						var split := _interpolate_vertex(arrays, a, b, a_y / (a_y - b_y))
						lower.append(split)
						upper.append(split)
				if lower.size() >= 3:
					pieces.append(lower)
				if upper.size() >= 3:
					pieces.append(upper)
			polygons = pieces
		for piece in polygons:
			for corner in range(1, piece.size() - 1):
				result.append_array(PackedInt32Array([piece[0], piece[corner], piece[corner + 1]]))
	arrays[Mesh.ARRAY_INDEX] = result


static func _interpolate_vertex(arrays: Array, a: int, b: int, weight: float) -> int:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var influences := bones.size() / vertices.size()
	var index := vertices.size()
	for channel in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
		if arrays[channel] != null and not arrays[channel].is_empty():
			var data = arrays[channel]
			var value = data[a].lerp(data[b], weight)
			data.append(value.normalized() if channel == Mesh.ARRAY_NORMAL else value)
			arrays[channel] = data
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	if not tangents.is_empty():
		for component in range(4):
			tangents.append(lerpf(tangents[a * 4 + component], tangents[b * 4 + component], weight))
		arrays[Mesh.ARRAY_TANGENT] = tangents
	var bone_weights: Dictionary = {}
	for slot in influences:
		var a_bone := bones[a * influences + slot]
		var b_bone := bones[b * influences + slot]
		bone_weights[a_bone] = bone_weights.get(a_bone, 0.0) + weights[a * influences + slot] * (1.0 - weight)
		bone_weights[b_bone] = bone_weights.get(b_bone, 0.0) + weights[b * influences + slot] * weight
	var keys := bone_weights.keys()
	keys.sort_custom(func(left: int, right: int): return bone_weights[left] > bone_weights[right])
	var total := 0.0
	for slot in mini(influences, keys.size()):
		total += bone_weights[keys[slot]]
	for slot in influences:
		bones.append(keys[slot] if slot < keys.size() else 0)
		weights.append(bone_weights[keys[slot]] / total if slot < keys.size() else 0.0)
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	return index


static func _find_hand_bind(skin: Skin, hand_name: StringName, hand: int) -> int:
	for bind in skin.get_bind_count():
		if skin.get_bind_name(bind) == hand_name or (skin.get_bind_name(bind).is_empty() and skin.get_bind_bone(bind) == hand):
			return bind
	return -1


static func fit_handle(umbrella: Node3D) -> void:
	# The supplied pole is wider than the NPC palm. Narrow its handle and shaft
	# surfaces to fit the grip, preserving the canopy's original size and shape.
	for child in umbrella.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var source := instance.mesh
		var fitted := ArrayMesh.new()
		for surface in source.get_surface_count():
			var arrays := source.surface_get_arrays(surface).duplicate(true)
			if surface != 1:
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				var sizing := Basis.from_scale(Vector3(0.35, 1.0, 0.35))
				for vertex in vertices.size():
					vertices[vertex] = sizing * vertices[vertex]
					if not normals.is_empty():
						normals[vertex] = (sizing.inverse().transposed() * normals[vertex]).normalized()
					if not tangents.is_empty():
						var tangent := sizing * Vector3(tangents[vertex * 4], tangents[vertex * 4 + 1], tangents[vertex * 4 + 2])
						tangent = tangent.normalized()
						tangents[vertex * 4] = tangent.x
						tangents[vertex * 4 + 1] = tangent.y
						tangents[vertex * 4 + 2] = tangent.z
				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_NORMAL] = normals
				arrays[Mesh.ARRAY_TANGENT] = tangents
			fitted.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays)
			fitted.surface_set_material(surface, source.surface_get_material(surface))
		instance.mesh = fitted
