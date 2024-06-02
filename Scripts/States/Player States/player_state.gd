class_name PlayerState

extends State

var player : CharacterBody3D

func _ready():
	await owner.ready
	player = owner as CharacterBody3D
	assert (player != null)
