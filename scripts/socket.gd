extends Area3D

@onready var socket_marker = $Marker3D

func socket_item(item):
	# item = floppy disk
	if item and item.has_method("socket_item") and not item.is_inserted:
		item.socket_item(socket_marker.global_transform, self)
