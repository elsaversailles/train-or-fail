extends Node

var mode := "fd"

func get_session_applicants() -> Array:
	var data: Dictionary
	match mode:
		"fd":
			data = {
				"name": "Alyssa Cruz",
				"model_scene": load("res://models3d/characters/F/alyssa_cruz.tscn"),
				"location": load("res://images/applicants info/FraudDetection/a2/fd_r02_location_convenience_counter.png"),
				"item": load("res://images/applicants info/FraudDetection/a2/fd_r02_item_laundry_detergent.png"),
				"time": "9:15 AM", "price": "₱240", "ai_risk_factor": "6%",
				"note": "Routine detergent purchase at a familiar convenience store; normal amount and daytime activity.",
				"fraud_correct": "legit"
			}
		"kyc":
			data = {
				"name": "Maria Santos",
				"model_scene": load("res://models3d/characters/F/maria_santos.tscn"),
				"id_image": load("res://images/applicants info/KYC/a1/a1_id.png"),
				"ai_risk_factor": "10%",
				"note": "Government ID hologram, photo, and personal details match national registry records with no discrepancies.",
				"kyc_correct": "legit"
			}
		_:
			data = {
				"name": "Mark Reyes",
				"model_scene": load("res://models3d/characters/M/mark_reyes.tscn"),
				"general_info_img": load("res://images/applicants info/CreditScoring/a1/cs_a1_GI.png"),
				"payment_history_img": load("res://images/applicants info/CreditScoring/a1/cs_a1_PH.png"),
				"arrears_img": load("res://images/applicants info/CreditScoring/a1/cs_a1_arrears.png"),
				"debt_ratio_img": load("res://images/applicants info/CreditScoring/a1/cs_a1_DR.png"),
				"ai_risk_factor": "7%", "credit_correct": 1.0
			}
	return [data, data, data, data, data]
