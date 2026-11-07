extends Node3D


func _ready() -> void:
	$FraudDetection.visible = SaveManager.has_certificate("fraud_detection")
	$KnowYourCustomer.visible = SaveManager.has_certificate("know_your_customer")
	$CreditScoring.visible = SaveManager.has_certificate("credit_scoring")
