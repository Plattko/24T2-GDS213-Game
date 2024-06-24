extends Node

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"

# Player reference
var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")

var players_spawn_node

func become_host() -> void:
	print("Starting host.")
	
	# Establishes the player spawn node - Server-side only
	players_spawn_node = get_tree().current_scene.get_node("Players")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	# Lifecycle callbacks
	multiplayer.peer_connected.connect(add_player_to_game) # Calls this function when a peer connects to the server
	multiplayer.peer_disconnected.connect(remove_player_from_game)
	
	remove_singleplayer_player()
	
	# Manually add the player to the server because peer connected isn't called
	add_player_to_game(1)

func join_as_player_2() -> void:
	print("Player 2 joining.")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	remove_singleplayer_player()

func add_player_to_game(id: int) -> void:
	print("Player %s joined the game!" % id)
	
	# Instantiate the multiplayer player scene
	var player_to_add = multiplayer_player.instantiate()
	
	# Set the player's ID and name
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	players_spawn_node.add_child(player_to_add)

func remove_player_from_game(id: int) -> void:
	print("Player %s left the game!" % id)
	
	var player_to_remove = players_spawn_node.get_node(str(id))
	if player_to_remove:
		player_to_remove.queue_free()
		player_to_remove = null

func remove_singleplayer_player() -> void:
	print("Remove singleplayer Player.")
	var player_to_remove = get_tree().current_scene.get_node("Player")
	player_to_remove.queue_free()
	player_to_remove = null
