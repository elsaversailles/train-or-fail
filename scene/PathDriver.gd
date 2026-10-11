extends PathFollow3D

@export var speed := 8.0     

@onready var jeepney := $Jeepney    

func _process(delta: float) -> void:
	progress += speed * delta         
	jeepney.speed = speed              
