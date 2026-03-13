extends Area3D

@onready var socket_marker = $Marker3D # Position this Marker3D inside the wall hole

func socket_item(item):
	# 'item' is the floppy disk being passed from the player
	if item.has_method("socket_item") and not item.is_inserted:
		# We call the disk's own function to handle the physics/reparenting
		item.socket_item(socket_marker.global_transform)
