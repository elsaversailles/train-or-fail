extends Node

var applicant_count: int = 2

func get_session_applicants() -> Array:
	var photo := GradientTexture2D.new()
	var applicants: Array = []
	for index in range(applicant_count):
		var model := Node3D.new()
		model.name = "Applicant%d" % index
		var mesh := MeshInstance3D.new()
		mesh.mesh = CapsuleMesh.new()
		model.add_child(mesh)
		mesh.owner = model
		var packed := PackedScene.new()
		packed.pack(model)
		model.free()
		applicants.append({"id": "test_%d" % index, "is_special": index == 0, "name": "Test Applicant %d" % index, "location": photo, "id_image": photo, "kyc_correct": "legit" if index == 0 else "sus", "item": photo, "time": "12:00", "price": "100", "ai_risk_factor": "50%", "note": "Applicant notes.", "general_info_img": photo, "payment_history_img": photo, "arrears_img": photo, "debt_ratio_img": photo, "model_scene": packed, "fraud_correct": "legit" if index == 0 else "sus", "credit_correct": 0.8 if index == 0 else 0.0})
	return applicants
