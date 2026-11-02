extends Node
func get_session_applicants() -> Array:
 var photo = GradientTexture2D.new()
 return [{"name": "UI Test Applicant", "location": photo, "item": photo, "time": "12:00", "price": "100", "ai_risk_factor": "50%", "note": "Test applicant notes.", "id_image": photo, "model_scene": null, "fraud_correct": "legit", "kyc_correct": "legit", "credit_correct": 0.5}]
