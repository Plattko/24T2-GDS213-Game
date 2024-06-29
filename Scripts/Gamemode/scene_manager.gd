extends Node3D

@export var multiplayer_player : PackedScene
@export var spawn_points : Array[Node3D] = []

func _ready() -> void:
	var index := 0
	for n in GameManager.players:
		var player = multiplayer_player.instantiate()
		add_child(player)
		# Set the player's location to their spawn point
		print("Spawn point: %s" % spawn_points[index])
		player.global_position = spawn_points[index].global_position
		index += 1
