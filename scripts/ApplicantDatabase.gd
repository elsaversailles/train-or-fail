extends Node

# --- THE MASTER POOL ---
# Add as many applicants as you want here. The game will pick 5 randomly!
var all_applicants = [
	{
		"id": "a1",
		"name": "Elias Thorne",
		
		"model_scene": preload("res://scene/Applicants/F/f_buns.tscn"),
		
		# Fraud Detection
		"location": preload("res://images/applicants info/day1/a1/a1_location.png"),
		"item": preload("res://images/applicants info/day1/a1/a1_item.jpg"),
		"time": "11:45 AM",
		"price": "₱1,550",
		"fraud_correct": "legit", 
		
		# KYC
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"kyc_correct": "legit",   
		
		# Credit Scoring
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/day1/a1/a1_item.jpg")
	},
	{
		"id": "a2",
		"name": "Marcus Vane",
		
		"model_scene": preload("res://scene/Applicants/F/f_long_hair.tscn"),
		
		"location": preload("res://images/applicants info/day1/a2/a2_location.png"),
		"item": preload("res://images/applicants info/day1/a2/a2_item.png"),
		"time": "3:12 AM",
		"price": "₱450,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"kyc_correct": "sus", 
		
		"payment": "bad",
		"arrears": true,
		"debt_ratio": "high",
		"credit_img": preload("res://images/applicants info/day1/a2/a2_item.png")
	},
	{
		"id": "a3",
		"name": "Sarah Jenkins",
		
		"model_scene": preload("res://scene/Applicants/F/f_long_shaggy.tscn"),
		
		"location": preload("res://images/applicants info/day1/a3/a3_location.png"),
		"item": preload("res://images/applicants info/day1/a3/a3_item.jpg"),
		"time": "8:30 AM",
		"price": "₱210",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/day1/a3/a3_item.jpg")
	},
	{
		"id": "a4",
		"name": "Charlie Brown",
		
		"model_scene": preload("res://scene/Applicants/F/f_mullet.tscn"),
		
		"location": preload("res://images/applicants info/day1/a4/a4_location.png"),
		"item": preload("res://images/applicants info/day1/a4/a4_item.jpg"),
		"time": "2:22 AM",
		"price": "₱25,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"kyc_correct": "sus",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "high",
		"credit_img": preload("res://images/applicants info/day1/a4/a4_item.jpg")
	},
	{
		"id": "a5",
		"name": "Linda Miller",
		
		"model_scene": preload("res://scene/Applicants/F/f_ponytail_high.tscn"),
		
		"location": preload("res://images/applicants info/day1/a5/a5_location.png"),
		"item": preload("res://images/applicants info/day1/a5/a5_item.png"),
		"time": "5:30 PM",
		"price": "₱3,200",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/day1/a5/a5_item.png")
	}
]

# Pick 5 random applicants
func get_session_applicants() -> Array:
	var pool = all_applicants.duplicate()
	pool.shuffle()
	return pool.slice(0, 5)
