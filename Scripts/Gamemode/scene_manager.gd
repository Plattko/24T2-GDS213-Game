extends Node3D

var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")

@export_group("Initial Spawn Points")
@export var spawn_points : Array[Node3D] = []

# Zone variables
@export_group("Zone Variables")
@export var zone_respawn_points : Array[Node3D] = []
var cur_zone : int = 1

func _ready() -> void:
	if !multiplayer.is_server():
		return
	
	#TODO: Instantiate the UI
	
	var index := 0
	# Spawn the players
	for i in GameManager.players:
		var player = multiplayer_player.instantiate()
		# Set the player's name to their unique ID
		player.name = str(GameManager.players[i].id)
		# Add the player as a child of the scene
		add_child(player)
		
		## Set the player's location to their spawn point
		#print("Spawn point: %s" % spawn_points[index])
		#player.global_position = spawn_points[index].global_position
		
		# If it's player 1, manually set their initial spawn point
		if GameManager.players[i].player_num == 1:
			set_initial_spawn_position(player)
		
		#TODO: Connect the UI to the player
		
		index += 1
	
	# Set the current respawn point
	set_respawn_point.rpc()

## Temporary fix TODO: Make work differently
func _on_multiplayer_spawner_spawned(node):
	print("Spawned player " + str(node.name) + " on client " + str(multiplayer.get_unique_id()))
	set_initial_spawn_position(node)
	
	#var spawn_point = spawn_points.pop_front()
	#node.global_position = spawn_point.global_position
	#print("Player " + str(node.name) + " spawned at: " + str(node.global_position))

func set_initial_spawn_position(player) -> void:
	var player_num = GameManager.players[player.name.to_int()].player_num
	player.global_position = spawn_points[player_num - 1].global_position

@rpc("any_peer", "call_local")
func set_respawn_point() -> void:
	GameManager.cur_respawn_point = zone_respawn_points[cur_zone - 1].global_position
