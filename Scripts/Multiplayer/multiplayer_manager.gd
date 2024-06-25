extends Node

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"
const MAX_PLAYERS := 4

var server_peer

var is_multiplayer : bool = false

# Player reference
var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")

var players_spawn_node

func become_host() -> void:
	print("Starting host.")
	# Establishes the player spawn node - Server-side only
	players_spawn_node = get_tree().current_scene.get_node("Players")
	
	# Create a new peer
	server_peer = ENetMultiplayerPeer.new()
	# Check for an error creating the server
	var error = server_peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error != OK:
		print("Cannot host: %s" % error)
		return
	# Apply compression to reduce bandwidth use NOTE: Can be disabled if it causes issues
	server_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# Sets the server peer as my peer
	multiplayer.set_multiplayer_peer(server_peer) #multiplayer.multiplayer_peer = server_peer
	print("Waiting for players!")
	
	# Lifecycle callbacks
	multiplayer.peer_connected.connect(add_player_to_game) # Calls this function when a peer connects to the server
	multiplayer.peer_disconnected.connect(remove_player_from_game)
	
	is_multiplayer = true
	
	remove_singleplayer_player()
	
	# Manually add the player to the server because peer connected isn't called
	add_player_to_game(1)

func join_as_player_2() -> void:
	print("Player 2 joining.")
	# Create a new peer
	var client_peer = ENetMultiplayerPeer.new()
	# Make it a client of the chosen server
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	# Apply compression to reduce bandwidth use NOTE: Can be disabled if it causes issues
	client_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	# Set yourself as the multiplayer peer
	multiplayer.set_multiplayer_peer(client_peer) #multiplayer.multiplayer_peer = client_peer
	
	remove_singleplayer_player()

# Is called on the server and clients when someone connects
func add_player_to_game(id: int) -> void:
	print("Player %s connected!" % id)
	
	# Instantiate the multiplayer player scene
	var player_to_add = multiplayer_player.instantiate()
	
	# Set the player's ID and name
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	players_spawn_node.add_child(player_to_add)

# Is called on the server and clients when someone disconnects
func remove_player_from_game(id: int) -> void:
	print("Player %s disconnected!" % id)
	
	var player_to_remove = players_spawn_node.get_node(str(id))
	if player_to_remove:
		player_to_remove.queue_free()
		player_to_remove = null

# Is called only from clients
# If you want to send information from the client to the server, do it from here
func connected_to_server() -> void: 
	print("Connected to server.")

# Is called only from clients
func connection_failed() -> void: 
	print("Connection failed.")

func remove_singleplayer_player() -> void:
	print("Remove singleplayer Player.")
	var player_to_remove = get_tree().current_scene.get_node("Player")
	player_to_remove.queue_free()
	player_to_remove = null
