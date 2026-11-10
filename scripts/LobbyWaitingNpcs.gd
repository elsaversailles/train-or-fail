extends Node3D
## Ambient visitors belong only to the reception waiting chairs, not staff desks.

const SeatedPose := preload("res://scripts/LobbySeatedPose.gd")
# Matches the supervisor's actual rig size, including its different import scale.
const VISITOR_SCALE := 2.475
const SEAT_ANCHOR := Vector3(0.0, 22.0, 12.0)
const CHARACTER_PATHS := [
	"res://models3d/characters/M/adrian_santos.tscn",
	"res://models3d/characters/M/alex_rivera.tscn",
	"res://models3d/characters/M/antonio_garcia.tscn",
	"res://models3d/characters/M/juan_perez.tscn",
	"res://models3d/characters/M/miguel_reyes.tscn",
	"res://models3d/characters/M/rico_tan.tscn",
	"res://models3d/characters/F/anna_reyes.tscn",
	"res://models3d/characters/F/andrea_mendoza.tscn",
	"res://models3d/characters/F/carmen_bautista.tscn",
	"res://models3d/characters/F/maria_santos.tscn",
	"res://models3d/characters/F/teresa_lim.tscn",
	"res://models3d/characters/F/trisha_aquino.tscn",
]

@export_node_path("Node3D") var lobby_model: NodePath


func _ready() -> void:
	var model := get_node(lobby_model)
	var chairs: Array[Node3D] = []
	# These 25 seats are the rows in front of reception. Other chair meshes
	# belong to the counters and office workstations and must remain untouched.
	for index in range(23, 48):
		var chair := model.get_node_or_null("Chair_Conference_%03d" % index) as Node3D
		if chair:
			chairs.append(chair)
	chairs.shuffle()
	var characters := CHARACTER_PATHS.duplicate()
	characters.shuffle()
	var count := mini(randi_range(5, 7), chairs.size())
	for index in count:
		var chair := chairs[index]
		var visitor := load(characters[index]).instantiate() as Node3D
		visitor.name = "WaitingVisitor%d" % (index + 1)
		visitor.set_meta("waiting_chair", chair.name)
		add_child(visitor)
		# Match the chair's forward direction (+Z), without inheriting the tiny
		# imported furniture scale. Character scenes already normalize their rigs.
		visitor.global_basis = chair.global_basis.orthonormalized().scaled(Vector3.ONE * VISITOR_SCALE)
		var hip_position := visitor.to_global(SeatedPose.apply(visitor))
		# Sit above the cushion and far enough forward for knees to clear its edge.
		var seat_position := chair.to_global(SEAT_ANCHOR)
		visitor.global_position += seat_position - hip_position
