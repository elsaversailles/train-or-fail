extends Area3D

# Drag your 'Screen' CSGBox3D into this slot in the Inspector
@export var screen_node : CSGBox3D 

func interact():
	if screen_node:
		# Toggle between Union (0) and Subtraction (2)
		if screen_node.operation == CSGBox3D.OPERATION_UNION:
			screen_node.operation = CSGBox3D.OPERATION_SUBTRACTION
			print("Screen set to Subtraction")
		else:
			screen_node.operation = CSGBox3D.OPERATION_UNION
			print("Screen set to Union")
