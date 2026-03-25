extends Control

var is_open = false
var panel_width = 944

func _ready():
	# Connect the buttons
	$GripButton.pressed.connect(grip_pressed)
	

func grip_pressed():
	slide_panel()

func slide_panel():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if is_open:
		# "close" slide LEFT 
		tween.tween_property(self, "position:x", -panel_width, 0.6)
	else:
		# "open" slide RIGHT 
		tween.tween_property(self, "position:x", -3, 0.6)
	
	is_open = !is_open
