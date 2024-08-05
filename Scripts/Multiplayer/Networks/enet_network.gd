extends Node

var multiplayer_manager : MultiplayerManager

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connected_to_server
signal connection_failed

func _ready():
	# Connect lifecycle callbacks
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)

#-------------------------------------------------------------------------------
# Buttons
#-------------------------------------------------------------------------------
func become_host() -> void:
	print("Starting host.")
	# Make the player the host of a server
	var error = multiplayer_peer.create_server(SERVER_PORT, multiplayer_manager.max_players)
	if error == OK:
		# Apply compression to reduce bandwidth use
		# NOTE: Can be disabled if it causes issues
		multiplayer_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		
		# Set yourself as the server peer
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		print("Waiting for players!")
		
		# Pass in the host's player information
		multiplayer_manager.add_player_to_lobby(multiplayer.get_unique_id(), multiplayer_manager.name_line.text)
		print("Added player to lobby from ENet network")
	# If there is an error creating the server, print the error
	else:
		print("Cannot host: %s" % error)

func join_as_client(_lobby_id: int) -> void:
	print("Player 2 joining.")
	# Make the player a client of the chosen server
	var error = multiplayer_peer.create_client(multiplayer_manager.get_server_ip(SERVER_IP), SERVER_PORT)
	# Check for an error creating the client
	if error == OK:
		# Apply compression to reduce bandwidth use
		# NOTE: Can be disabled if it causes issues
		multiplayer_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		# Set yourself as the multiplayer peer
		multiplayer.set_multiplayer_peer(multiplayer_peer)
	else:
		print("Cannot create client: %s" % error)

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
func on_peer_connected(id: int) -> void:
	multiplayer_manager.on_peer_connected(id)

func on_peer_disconnected(id: int) -> void:
	multiplayer_manager.on_peer_disconnected(id)

func on_connected_to_server() -> void:
	multiplayer_manager.on_connected_to_server(multiplayer_manager.name_line.text)

func on_connection_failed() -> void: 
	multiplayer_manager.on_connection_failed()
