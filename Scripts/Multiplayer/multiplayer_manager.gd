extends Node

@export var name_line : LineEdit
@export var ip_line : LineEdit
var network_testing_scene = preload("res://Scenes/Levels/Testing/rocket-jump-testing.tscn")

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"
const MAX_PLAYERS := 4

var cur_player_num := 2

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
	# Create a new peer
	var server_peer = ENetMultiplayerPeer.new()
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
	send_player_information(multiplayer.get_unique_id(), name_line.text, 1)

func _on_join_as_player_2_pressed() -> void:
	print("Player 2 joining.")
	# Create a new peer
	var client_peer = ENetMultiplayerPeer.new()
	# Make it a client of the chosen server
	var error = client_peer.create_client(get_server_ip(), SERVER_PORT)
	# Check for an error creating the client
	if error != OK:
		print("Cannot create client: %s" % error)
		return
	# Apply compression to reduce bandwidth use NOTE: Can be disabled if it causes issues
	client_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	# Set yourself as the multiplayer peer
	multiplayer.set_multiplayer_peer(client_peer) #multiplayer.multiplayer_peer = client_peer

func _on_start_game_pressed() -> void:
	# Call start_game on all peers
	start_game.rpc()

func get_server_ip() -> String:
	if ip_line.text != "":
		print("Server IP: " + ip_line.text)
		return ip_line.text
	else:
		print("Server IP: " + SERVER_IP)
		return SERVER_IP

#--------------------------------CONNECTIONS------------------------------------
## Formerly called add_player_to_game
# Is called on the server and clients when someone connects
func on_peer_connected(id: int) -> void:
	print("Player %s connected!" % id)

## Formerly called remove_player_from_game
# Is called on the server and clients when someone disconnects
func on_peer_disconnected(id: int) -> void:
	print("Player %s disconnected!" % id)
	# Delete the player
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
	# Remove the player from the players dictionary
	GameManager.players.erase(id)

# Is only called from clients
# If you want to send information from the client to the server, do it from here
func on_connected_to_server() -> void: 
	print("Connected to server.")
	# Send connected player's information to the server
	send_player_information.rpc_id(1, multiplayer.get_unique_id(), name_line.text, cur_player_num)
	cur_player_num += 1

# Is only called from clients
func on_connection_failed() -> void: 
	print("Connection failed.")

#------------------------------------RPCS---------------------------------------
@rpc("any_peer", "call_local")
func start_game() -> void:
	# Load the scene
	var scene = network_testing_scene.instantiate()
	# Add it to our tree
	get_tree().root.add_child(scene)
	# Hide the connection menu
	self.visible = false

## NOTE: Use this if players select weapon loadout before entering game
@rpc("any_peer")
func send_player_information(id, username, player_num) -> void:
	# If the player doesn't already exist, send the player information to the server
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"id" : id,
			"username" : username,
			"player_num" : player_num,
		}
	
	# Pass the player information from the server to every peer
	if multiplayer.is_server():
		for n in GameManager.players:
			send_player_information.rpc(n, GameManager.players[n].username, GameManager.players[n].player_num)
