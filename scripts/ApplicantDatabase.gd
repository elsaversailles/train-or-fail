extends Node

func _ready():
	randomize()

# ==========================================
# FRAUD DETECTION POOL (Days 1 - 3)
# ==========================================
var fraud_applicants: Array = [
	{
		"id": "fd_a1",
		"name": "Alyssa Cruz",
		"model_scene": preload("res://models3d/characters/F/alyssa_cruz.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a2/fd_r02_location_convenience_counter.png"),
		"item": preload("res://images/applicants info/FraudDetection/a2/fd_r02_item_laundry_detergent.png"),
		"time": "9:15 AM",
		"price": "₱240",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a2",
		"name": "Jomar Salazar",
		"model_scene": preload("res://models3d/characters/M/jomar_salazar.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a3/fd_r03_location_hardware_main_aisle.png"),
		"item": preload("res://images/applicants info/FraudDetection/a3/fd_r03_item_electric_stand_fan.png"),
		"time": "3:20 PM",
		"price": "₱1,850",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a3",
		"name": "Jake Meza",
		"model_scene": preload("res://models3d/characters/M/jake_meza.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a4/fd_r04_location_dark_unregistered_terminal.png"),
		"item": preload("res://images/applicants info/FraudDetection/a4/fd_r04_item_10_gaming_load_cards.png"),
		"time": "2:45 AM",
		"price": "₱15,000",
		"fraud_correct": "sus"
	},
	{
		"id": "fd_a4",
		"name": "Nico Ferrer",
		"model_scene": preload("res://models3d/characters/M/nico_ferrer.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a5/fd_r05_location_pharmacy_drive_thru.png"),
		"item": preload("res://images/applicants info/FraudDetection/a5/fd_r05_item_prescription_antibiotics.png"),
		"time": "1:10 PM",
		"price": "₱650",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a5",
		"name": "Trisha Aquino",
		"model_scene": preload("res://models3d/characters/F/trisha_aquino.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a6/fd_r06_location_department_store_shoes.png"),
		"item": preload("res://images/applicants info/FraudDetection/a6/fd_r06_item_two_leather_work_shoes.png"),
		"time": "5:40 PM",
		"price": "₱4,200",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a6",
		"name": "Carlo Herrer",
		"model_scene": preload("res://models3d/characters/M/carlo_herrer.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a8/fd_r08_location_dark_alley_terminal.png"),
		"item": preload("res://images/applicants info/FraudDetection/a8/fd_r08_item_five_graphics_cards.png"),
		"time": "3:12 AM",
		"price": "₱109,000",
		"fraud_correct": "sus"
	},
	{
		"id": "fd_a7",
		"name": "Angelo",
		"model_scene": preload("res://models3d/characters/M/angelo.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a9/fd_r09_location_coffee_drive_thru.png"),
		"item": preload("res://images/applicants info/FraudDetection/a9/fd_r09_item_iced_latte.png"),
		"time": "8:30 AM",
		"price": "₱210",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a8",
		"name": "Miguel Nava",
		"model_scene": preload("res://models3d/characters/M/miguel_nava.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a10/fd_r10_location_vpn_moscow_transaction.png"),
		"item": preload("res://images/applicants info/FraudDetection/a10/fd_r10_item_prepaid_gaming_credits.png"),
		"time": "2:22 AM",
		"price": "₱25,000",
		"fraud_correct": "sus"
	},
	{
		"id": "fd_a9",
		"name": "Adrian Santos",
		"model_scene": preload("res://models3d/characters/M/adrian_santos.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a10/fd_r10_location_vpn_moscow_transaction.png"),
		"item": preload("res://images/applicants info/FraudDetection/a10/fd_r10_item_prepaid_gaming_credits.png"),
		"time": "5:30 PM",
		"price": "₱3,200",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a10",
		"name": "Regine Manuel",
		"model_scene": preload("res://models3d/characters/F/regine_manuel.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a14/fd_r14_location_abandoned_warehouse_dock.png"),
		"item": preload("res://images/applicants info/FraudDetection/a14/fd_r14_item_ten_premium_smartphones.png"),
		"time": "11:55 PM",
		"price": "₱900,000",
		"fraud_correct": "sus"
	},
	{
		"id": "fd_a11",
		"name": "Briar Galima",
		"model_scene": preload("res://models3d/characters/M/briar_galima.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a15/fd_r15_location_fast_food_delivery.png"),
		"item": preload("res://images/applicants info/FraudDetection/a15/fd_r15_item_fast_food_family_meal.png"),
		"time": "6:45 PM",
		"price": "₱1,200",
		"fraud_correct": "legit"
	},
	{
		"id": "fd_a12",
		"name": "Michele Garcia",
		"model_scene": preload("res://models3d/characters/F/michele_garcia.tscn"),
		"location": preload("res://images/applicants info/FraudDetection/a16/fd_r16_location_camera_taped.png"),
		"item": preload("res://images/applicants info/FraudDetection/a16/fd_r16_item_luxury_watch.png"),
		"time": "4:00 AM",
		"price": "₱500,000",
		"fraud_correct": "sus"
	}
]

# KYC POOL (Days 4 - 6)
var kyc_applicants: Array = [
	{
		"id": "kyc_a1",
		"name": "Maria Santos",
		"model_scene": preload("res://models3d/characters/F/maria_santos.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a1/a1_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a2",
		"name": "Juan Perez",
		"model_scene": preload("res://models3d/characters/M/juan_perez.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a2/a2_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a3",
		"name": "Carlo Mendoza",
		"model_scene": preload("res://models3d/characters/M/carlo_herrer.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a3/a3_id.png"),
		"kyc_correct": "sus"
	},
	{
		"id": "kyc_a4",
		"name": "Teresa Lim",
		"model_scene": preload("res://models3d/characters/F/teresa_lim.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a4/a4_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a5",
		"name": "Miguel Reyes",
		"model_scene": preload("res://models3d/characters/M/miguel_reyes.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a5/a5_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a6",
		"name": "Anna Reyes",
		"model_scene": preload("res://models3d/characters/F/anna_reyes.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a6/a6_id.png"),
		"kyc_correct": "sus"
	},
	{
		"id": "kyc_a7",
		"name": "Rosa Dela Torre",
		"model_scene": preload("res://models3d/characters/F/rosa_dela_torre.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a7/a7_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a8",
		"name": "Aponilaryo Limaga",
		"model_scene": preload("res://models3d/characters/M/apolinaryo_limaga.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a8/a8_id.png"),
		"kyc_correct": "sust"
	},
	{
		"id": "kyc_a9",
		"name": "Carmen Bautista",
		"model_scene": preload("res://models3d/characters/F/carmen_bautista.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a9/a9_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a10",
		"name": "Alex Rivera",
		"model_scene": preload("res://models3d/characters/M/alex_rivera.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a10/a10_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a11",
		"name": "Mark Lim",
		"model_scene": preload("res://models3d/characters/M/mark_lim.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a11/a11_id.png"),
		"kyc_correct": "sus"
	},
	{
		"id": "kyc_a12",
		"name": "Jose Gonzales",
		"model_scene": preload("res://models3d/characters/M/jose_gonzales.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a12/a12_id.png"),
		"kyc_correct": "legit"
	},
	{
		"id": "kyc_a13",
		"name": " Ricardo Villanueva",
		"model_scene": preload("res://models3d/characters/M/ricardo_villanueva.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a13/a13_id.png"),
		"kyc_correct": "sus"
	},
	{
		"id": "kyc_a14",
		"name": "Antonio Garcia",
		"model_scene": preload("res://models3d/characters/M/antonio_garcia.tscn"),
		"id_image": preload("res://images/applicants info/KYC/a14/a14_id.png"),
		"kyc_correct": "sus"
	}
]

# ==========================================
# CREDIT SCORING POOL (Days 7 - 9)
# ==========================================
var credit_applicants: Array = [
	{
		"id": "cs_a1",
		"name": "Mark Reyes",
		"model_scene": preload("res://models3d/characters/M/mark_reyes.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a1/cs_a1_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a1/cs_a1_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a1/cs_a1_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a1/cs_a1_DR.png"),
		"credit_correct": 1.0
	},
	{
		"id": "cs_a2",
		"name": "Clara Lim",
		"model_scene": preload("res://models3d/characters/F/clara_lim.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a2/cs_a2_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a2/cs_a2_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a2/cs_a2_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a2/cs_a2_DR.png"),
		"credit_correct": 0.8
	},
	{
		"id": "cs_a3",
		"name": "Rico Tan",
		"model_scene": preload("res://models3d/characters/M/rico_tan.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a3/cs_a3_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a3/cs_a3_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a3/cs_a3_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a3/cs_a3_DR.png"),
		"credit_correct": 0.0
	},
	{
		"id": "cs_a4",
		"name": "Anita Go",
		"model_scene": preload("res://models3d/characters/F/anita_go.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a4/cs_a4_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a4/cs_a4_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a4/cs_a4_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a4/cs_a4_DR.png"),
		"credit_correct": 0.6
	},
	{
		"id": "cs_a5",
		"name": "Luis Sy",
		"model_scene": preload("res://models3d/characters/M/luis_sy.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a5/cs_a5_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a5/cs_a5_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a5/cs_a5_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a5/cs_a5_DR.png"),
		"credit_correct": 0.8
	},
	{
		"id": "cs_a6",
		"name": "Grandma Baba",
		"model_scene": preload("res://models3d/characters/F/grandma_baba.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a6/cs_a6_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a6/cs_a6_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a6/cs_a6_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a6/cs_a6_DR.png"),
		"credit_correct": 0.6
	},
	{
		"id": "cs_a7",
		"name": "John Bernard Adayo",
		"model_scene": preload("res://models3d/characters/M/john_bernard.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a7/cs_a7_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a7/cs_a7_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a7/cs_a7_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a7/cs_a7_DR.png"),
		"credit_correct": 0.4
	},
	{
		"id": "cs_a8",
		"name": "Nurse Clara Garcia",
		"model_scene": preload("res://models3d/characters/F/nurse_clara_garcia.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a8/cs_a8_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a8/cs_a8_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a8/cs_a8_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a8/cs_a8_DR.png"),
		"credit_correct": 0.4
	},
	{
		"id": "cs_a9",
		"name": "Meg Sy",
		"model_scene": preload("res://models3d/characters/F/meg_sy.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a9/cs_a9_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a9/cs_a9_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a9/cs_a9_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a9/cs_a9_DR.png"),
		"credit_correct": 0.4
	},
	{
		"id": "cs_a10",
		"name": "Jan Di",
		"model_scene": preload("res://models3d/characters/F/jan_di.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a10/cs_a10_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a10/cs_a10_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a10/cs_a10_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a10/cs_a10_DR.png"),
		"credit_correct": 0.2
	},
	{
		"id": "cs_a11",
		"name": "Alex Rivera",
		"model_scene": preload("res://models3d/characters/M/alex_rivera.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a11/cs_a11_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a11/cs_a11_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a11/cs_a11_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a11/cs_a11_DR.png"),
		"credit_correct": 0.0
	},
	{
		"id": "cs_a12",
		"name": "Prof. Jericho Santur",
		"model_scene": preload("res://models3d/characters/M/prof__jericho_santur.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a12/cs_a12_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a12/cs_a12_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a12/cs_a12_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a12/cs_a12_DR.png"),
		"credit_correct": 0.4
	},
	{
		"id": "cs_a13",
		"name": "Sol Ti",
		"model_scene": preload("res://models3d/characters/F/sol_ti.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a13/cs_a13_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a13/cs_a13_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a13/cs_a13_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a13/cs_a13_DR.png"),
		"credit_correct": 0.6
	},
	{
		"id": "cs_a14",
		"name": "Sam Lo",
		"model_scene": preload("res://models3d/characters/M/sam_lo.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a14/cs_a14_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a14/cs_a14_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a14/cs_a14_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a14/cs_a14_DR.png"),
		"credit_correct": 0.8
	},
	{
		"id": "cs_a15",
		"name": "Ben Jo",
		"model_scene": preload("res://models3d/characters/M/ben_jo.tscn"),
		"general_info_img": preload("res://images/applicants info/CreditScoring/a15/cs_a15_GI.png"),
		"payment_history_img": preload("res://images/applicants info/CreditScoring/a15/cs_a15_PH.png"),
		"arrears_img": preload("res://images/applicants info/CreditScoring/a15/cs_a15_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/CreditScoring/a15/cs_a15_DR.png"),
		"credit_correct": 0.2
	}
]

# ==========================================
# SPECIAL STORY CHARACTERS
# ==========================================
var special_applicants: Array = [
	{
		"id": "tita_elena",
		"target_day": 2,
		"is_special": true,
		"name": "Elena Dinorado",
		"model_scene": preload("res://models3d/characters/F/tita_elena.tscn"),
		"location": preload("res://images/applicants info/special characters/TitaElena/flour_location.png"),
		"item": preload("res://images/applicants info/special characters/TitaElena/flour_item.png"),
		"time": "11:45 AM",
		"price": "₱702,000.00",
		"fraud_correct": "sus",
		
		# Fallback data for safety
		"kyc_correct": "sus",
		"general_info_img": preload("res://images/creditscoring/general information/general info.png"),
		"payment_history_img": preload("res://images/creditscoring/payment history/Payment_History.png"),
		"arrears_img": preload("res://images/creditscoring/arrears/arrears.png"),
		"debt_ratio_img": preload("res://images/creditscoring/debt ratio/Debt_Ratio.png"),
		"credit_correct": 0.6
	},
	{
		"id": "mark_krazy",
		"target_day": [3, 5],
		"is_special": true,
		"name": "Mark Krazy",
		"model_scene": preload("res://models3d/characters/M/mark_krazy.tscn"),
		"location": preload("res://images/applicants info/special characters/MarkKrazy/atm_location.png"),
		"item": preload("res://images/applicants info/special characters/MarkKrazy/atm_item.png"),
		"time": "2:45 AM",
		"price": "₱15,000.00",
		"fraud_correct": "sus",
		
		"id_image": preload("res://images/applicants info/special characters/MarkKrazy/Mark_Krazy_ID.png"),
		"kyc_correct": "sus",
		
		"general_info_img": preload("res://images/creditscoring/general information/general info.png"),
		"payment_history_img": preload("res://images/creditscoring/payment history/Payment_History.png"),
		"arrears_img": preload("res://images/creditscoring/arrears/arrears.png"),
		"debt_ratio_img": preload("res://images/creditscoring/debt ratio/Debt_Ratio.png"),
		"credit_correct": 0.6
	},
	{
		"id": "nurse_clara",
		"target_day": [8],
		"is_special": true,
		"name": "Clara Garcia",
		"model_scene": preload("res://models3d/characters/F/nurse_clara_garcia.tscn"),
		
		"general_info_img": preload("res://images/applicants info/special characters/Clara Garcia/claragarcia_general_information.png"),
		"payment_history_img": preload("res://images/applicants info/special characters/Clara Garcia/claragarcia_payment_history.png"),
		"arrears_img": preload("res://images/applicants info/special characters/Clara Garcia/claragarcia_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/special characters/Clara Garcia/claragarcia_debt_ratio.png"),
		"credit_correct": 0.2
	},
	{
		"id": "jericho_santur",
		"target_day": [9],
		"is_special": true,
		"name": "Jericho Santur",
		"model_scene": preload("res://models3d/characters/M/prof__jericho_santur.tscn"),
		
		"general_info_img": preload("res://images/applicants info/special characters/JerichoSantur/jericho_generalinformation.png"),
		"payment_history_img": preload("res://images/applicants info/special characters/JerichoSantur/jericho_payment_history.png"),
		"arrears_img": preload("res://images/applicants info/special characters/JerichoSantur/jericho_arrears.png"),
		"debt_ratio_img": preload("res://images/applicants info/special characters/JerichoSantur/jericho_debt_ratio.png"),
		"credit_correct": 0.2
	}
]

# ==========================================
# SESSION APPLICANT SELECTION
# ==========================================
func get_session_applicants(department: String = "") -> Array:
	var current_day = SaveManager.current_save_data.get("current_day", 1)
	var pool: Array = []
	
	# Determine department automatically by current_day if not specified
	if department == "":
		if current_day <= 3:
			department = "fraud"
		elif current_day <= 6:
			department = "kyc"
		else:
			department = "credit"
			
	match department.to_lower():
		"fraud", "fraud_detection":
			pool = fraud_applicants.duplicate()
		"kyc", "know_your_customer":
			pool = kyc_applicants.duplicate()
		"credit", "credit_scoring":
			pool = credit_applicants.duplicate()

	pool.shuffle()

	# Check for a guaranteed special character on this day
	var guaranteed_applicant = null
	for special in special_applicants:
		var target = special.get("target_days", special.get("target_day"))
		if target is Array:
			if current_day in target:
				guaranteed_applicant = special
				break
		elif target == current_day:
			guaranteed_applicant = special
			break

	var session: Array = []
	if guaranteed_applicant != null:
		session = pool.slice(0, 4)
		session.append(guaranteed_applicant)
	else:
		session = pool.slice(0, 5)

	session.shuffle()
	return session
