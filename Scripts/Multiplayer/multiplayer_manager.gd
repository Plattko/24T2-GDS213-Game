extends Node

@export var name_line : LineEdit

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"
const MAX_PLAYERS := 4

var server_peer

var is_multiplayer : bool = false

# Player reference
var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")

var players_spawn_node

func _ready():
	# Connect lifecycle callbacks
	multiplayer.peer_connected.connect(on_peer_connected) # Calls this function when a peer connects to the server
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)

#---------------------------------BUTTONS---------------------------------------
## Formerly called become_host
func _on_host_new_game_pressed() -> void:
	print("Starting host.")
	## Establishes the player spawn node - Server-side only
	#players_spawn_node = get_tree().current_scene.get_node("Players")
	
	##--------------------------------------------------------------------------
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
	
	# Pass in the host's player information
	send_player_information(multiplayer.get_unique_id(), name_line.text)
	##--------------------------------------------------------------------------
	
	## Lifecycle callbacks
	#multiplayer.peer_connected.connect(add_player_to_game) # Calls this function when a peer connects to the server
	#multiplayer.peer_disconnected.connect(remove_player_from_game)
	#multiplayer.connected_to_server.connect(connected_to_server)
	#multiplayer.connection_failed.connect(connection_failed)
	
	#is_multiplayer = true
	
	#remove_singleplayer_player()
	
	## Manually add the player to the server because peer connected isn't called
	#add_player_to_game(1)

func _on_join_as_player_2_pressed() -> void:
	#print("Player 2 joining.")
	##--------------------------------------------------------------------------
	# Create a new peer
	var client_peer = ENetMultiplayerPeer.new()
	# Make it a client of the chosen server
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	# Apply compression to reduce bandwidth use NOTE: Can be disabled if it causes issues
	client_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	# Set yourself as the multiplayer peer
	multiplayer.set_multiplayer_peer(client_peer) #multiplayer.multiplayer_peer = client_peer
	##--------------------------------------------------------------------------
	
	#remove_singleplayer_player()

func _on_start_game_pressed() -> void:
	# Call start_game on all peers
	start_game.rpc()

#--------------------------------CONNECTIONS------------------------------------
## Formerly called add_player_to_game
# Is called on the server and clients when someone connects
func on_peer_connected(id: int) -> void:
	print("Player %s connected!" % id)
	
	## Instantiate the multiplayer player scene
	#var player_to_add = multiplayer_player.instantiate()
	
	## Set the player's ID and name
	#player_to_add.player_id = id
	#player_to_add.name = str(id)
	
	#players_spawn_node.add_child(player_to_add)

## Formerly called remove_player_from_game
# Is called on the server and clients when someone disconnects
func on_peer_disconnected(id: int) -> void:
	print("Player %s disconnected!" % id)
	
	#var player_to_remove = players_spawn_node.get_node(str(id))
	#if player_to_remove:
		#player_to_remove.queue_free()
		#player_to_remove = null

# Is called only from clients
# If you want to send information from the client to the server, do it from here
func on_connected_to_server() -> void: 
	print("Connected to server.")
	# Send connected player's information to the server
	send_player_information.rpc_id(1, multiplayer.get_unique_id(), name_line.text)

# Is called only from clients
func on_connection_failed() -> void: 
	print("Connection failed.")

#-------------------------------------------------------------------------------
@rpc("any_peer", "call_local")
func start_game() -> void:
	# Load the scene
	var scene = load("res://Scenes/Levels/Testing/network-testing.tscn").instantiate()
	# Add it to our tree
	get_tree().root.add_child(scene)
	# Hide the connection menu
	self.visible = false

## NOTE: Use this if players select weapon loadout before entering game
@rpc("any_peer")
func send_player_information(id, name) -> void:
	# If the player doesn't already exist, send the player information to the server
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"id" : id,
			"name" : name,
		}
	
	# Pass the player information from the server to every peer
	if multiplayer.is_server():
		for n in GameManager.players:
			send_player_information.rpc(n, GameManager.players[n].name)

func remove_singleplayer_player() -> void:
	print("Remove singleplayer Player.")
	var player_to_remove = get_tree().current_scene.get_node("Player")
	player_to_remove.queue_free()
	player_to_remove = null
