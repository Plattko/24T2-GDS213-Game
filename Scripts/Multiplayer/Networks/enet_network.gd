extends Node

#var multiplayer_manager : MultiplayerManager
var multiplayer_connection_menu : MultiplayerConnectionMenu
var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

# Server variables
const SERVER_PORT := 8080
const SERVER_IP = "127.0.0.1"

var lobby_name : String

func _ready():
	# Connect lifecycle callbacks
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)

#-------------------------------------------------------------------------------
# Hosting
#-------------------------------------------------------------------------------
func become_host(_lobby_name: String, _is_private: bool, _password: String) -> void:
	print("Starting host.")
	# Set the lobby name
	lobby_name = _lobby_name
	# Make the player the host of a server
	var error = multiplayer_peer.create_server(SERVER_PORT, multiplayer_connection_menu.max_players)
	if error == OK:
		# Apply compression to reduce bandwidth use
		# NOTE: Can be disabled if it causes issues
		multiplayer_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		# Set yourself as the server peer
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		print("Waiting for players!")
		# Pass in the host's player information
		multiplayer_connection_menu.add_player_to_lobby(multiplayer.get_unique_id(), multiplayer_connection_menu.lan_multiplayer_menu.host_username)
		print("Added player to lobby from ENet network")
		# Notify the multiplayer connection menu that the lobby has been created
		multiplayer_connection_menu.on_lobby_created()
	# If there is an error creating the server, print the error
	else:
		print("Cannot host: %s" % error)

#-------------------------------------------------------------------------------
# Joining
#-------------------------------------------------------------------------------
func join_as_client(_lobby_id: int) -> void:
	print("Player joining.")
	# Make the player a client of the chosen server
	var error = multiplayer_peer.create_client(multiplayer_connection_menu.lan_multiplayer_menu.get_server_ip(SERVER_IP), SERVER_PORT)
	# Check for an error creating the client
	if error == OK:
		# Apply compression to reduce bandwidth use
		# NOTE: Can be disabled if it causes issues
		multiplayer_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		# Establish the client as a multiplayer peer
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		# Notify the multiplayer connection menu that the lobby has been joined
		multiplayer_connection_menu.on_lobby_joined()
	else:
		print("Cannot create client: %s" % error)

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
func on_peer_connected(id: int) -> void:
	multiplayer_connection_menu.on_peer_connected(id)

func on_peer_disconnected(id: int) -> void:
	multiplayer_connection_menu.on_peer_disconnected(id)

func on_connected_to_server() -> void:
	multiplayer_connection_menu.on_connected_to_server(multiplayer_connection_menu.lan_multiplayer_menu.join_username)

func on_connection_failed() -> void: 
	multiplayer_connection_menu.on_connection_failed()
