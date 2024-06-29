extends Node3D

var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")
@export var spawn_points : Array[Node3D] = []

func _ready() -> void:
	if !multiplayer.is_server():
		return
	
	var index := 0
	for n in GameManager.players:
		var player = multiplayer_player.instantiate()
		# Set the player's name to their unique ID
		player.name = str(GameManager.players[n].id)
		# Add the player as a child of the scene
		add_child(player)
		# Set the player's location to their spawn point
		print("Spawn point: %s" % spawn_points[index])
		player.global_position = spawn_points[index].global_position
		index += 1

func _on_multiplayer_spawner_spawned(node):
	print("Spawned player " + str(node.name) + " on client " + str(multiplayer.get_unique_id()))
