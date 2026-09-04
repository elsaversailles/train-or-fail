extends Node

func _ready():
	randomize()

# Add as many applicants as you want here. The game will pick 5 randomly!
var all_applicants = [
	{
		"id": "a1",
		"name": "Elias Thorne",
		
		"model_scene": preload("res://scene/Applicants/F/f_buns.tscn"),
		
		"location": preload("res://images/applicants info/a1/a1_location.png"),
		"item": preload("res://images/applicants info/a1/a1_item.jpg"),
		"time": "11:45 AM",
		"price": "₱1,550",
		"fraud_correct": "legit", 
		
		"id_image": preload("res://images/applicants info/a1/a1_id.png"),
		"kyc_correct": "legit",   
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a1/a1_item.jpg"),
		"credit_correct": 0.6
	},
	{
		"id": "a2",
		"name": "Marcus Vane",
		
		"model_scene": preload("res://assets/Applicants/M/M BASE.glb"),
		
		"location": preload("res://images/applicants info/a2/a2_location.png"),
		"item": preload("res://images/applicants info/a2/a2_item.png"),
		"time": "3:12 AM",
		"price": "₱450,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "sus", 
		
		"payment": "bad",
		"arrears": true,
		"debt_ratio": "high",
		"credit_img": preload("res://images/applicants info/a2/a2_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a3",
		"name": "Sarah Jenkins",
		
		"model_scene": preload("res://scene/Applicants/F/f_long_shaggy.tscn"),
		
		"location": preload("res://images/applicants info/a3/a3_location.png"),
		"item": preload("res://images/applicants info/a3/a3_item.jpg"),
		"time": "8:30 AM",
		"price": "₱210",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/a3/a3_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a3/a3_item.jpg"),
		"credit_correct": 0.6
	},
	{
		"id": "a4",
		"name": "Charlie Brown",
		
		"model_scene": preload("res://assets/Applicants/M/M MOHAWK.glb"),
		
		"location": preload("res://images/applicants info/a4/a4_location.png"),
		"item": preload("res://images/applicants info/a4/a4_item.jpg"),
		"time": "2:22 AM",
		"price": "₱205,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "sus",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "high",
		"credit_img": preload("res://images/applicants info/a4/a4_item.jpg"),
		"credit_correct": 0.6
	},
	{
		"id": "a5",
		"name": "Linda Miller",
		
		"model_scene": preload("res://scene/Applicants/F/f_ponytail_high.tscn"),
		
		"location": preload("res://images/applicants info/a5/a5_location.png"),
		"item": preload("res://images/applicants info/a5/a5_item.png"),
		"time": "5:30 PM",
		"price": "₱3,200",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a6",
		"name": "Kate Ignacio",
		
		"model_scene": preload("res://scene/Applicants/F/f_ponytail_high.tscn"),
		
		"location": preload("res://images/applicants info/a6/bracelet_location.png"),
		"item": preload("res://images/applicants info/a6/bracelet_item.png"),
		"time": "1:00 AM",
		"price": "₱1,200,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a7",
		"name": "Resymarc Gabillete",
		
		"model_scene": preload("res://assets/Applicants/M/M BALD.glb"),
		
		"location": preload("res://images/applicants info/a7/notebook_location.png"),
		"item": preload("res://images/applicants info/a7/notebook_item.jpg"),
		"time": "2:15 PM",
		"price": "₱90",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a8",
		"name": "Regine Manuel",
		
		"model_scene": preload("res://assets/Applicants/F/F SHORT HAIR.glb"),
		
		"location": preload("res://images/applicants info/a8/iphone_location.png"),
		"item": preload("res://images/applicants info/a8/iphone_item.png"),
		"time": "11:55 PM",
		"price": "₱900,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a9",
		"name": "Briar Galima",
		
		"model_scene": preload("res://assets/Applicants/M/M LONG HAIR.glb"),
		
		"location": preload("res://images/applicants info/a9/jolibee_location.png"),
		"item": preload("res://images/applicants info/a9/jolibee_item.png"),
		"time": "6:45 PM",
		"price": "₱1,200",
		"fraud_correct": "legit",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	},
	{
		"id": "a10",
		"name": "Michele Garcia",
		
		"model_scene": preload("res://assets/Applicants/F/F SHORT HAIR.glb"),
		
		"location": preload("res://images/applicants info/a10/luxurywatch_location.png"),
		"item": preload("res://images/applicants info/a10/luxurywatch_item.png"),
		"time": "4:00 AM",
		"price": "₱500,000",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/a2/a2_id.png"),
		"kyc_correct": "legit",
		
		"payment": "good",
		"arrears": false,
		"debt_ratio": "low",
		"credit_img": preload("res://images/applicants info/a5/a5_item.png"),
		"credit_correct": 0.6
	}
]

# Pick 5 random applicants
func get_session_applicants() -> Array:
	var pool = all_applicants.duplicate()
	pool.shuffle()
	return pool.slice(0, 5)
