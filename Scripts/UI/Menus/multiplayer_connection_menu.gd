class_name MultiplayerConnectionMenu
extends Control

@export_group("Network Management")
@export var network_manager : NetworkManager
@export var is_using_steam : bool = false

@export_group("Menus")
@export var steam_multiplayer_menu : SteamMultiplayerMenu
@export var multiplayer_lobby_menu : MultiplayerLobbyMenu

@export_group("Level")
@export var level_node : Node
var multiplayer_level := load("res://Scenes/Levels/Testing/steam_multiplayer_testing.tscn")

# Multiplayer management
var max_players : int = 4
var player_count : int = 0
var players : Dictionary = {}

func _ready() -> void:
	network_manager.multiplayer_connection_menu = self
	
	if is_using_steam:
		use_steam()
		steam_multiplayer_menu.refresh_lobbies_requested.connect(list_steam_lobbies)
		steam_multiplayer_menu.join_lobby_requested.connect(join_lobby)
		steam_multiplayer_menu.create_lobby_requested.connect(create_lobby)
	
	multiplayer_lobby_menu.start_game_requested.connect(start_game)

func use_steam() -> void:
	print("Using Steam!")
	# Initialise steam
	SteamManager.initialise_steam()
	# Connect the lobby match list signal
	Steam.lobby_match_list.connect(on_lobby_match_list)
	# Set the active network type to Steam
	network_manager.active_network_type = NetworkManager.Multiplayer_Network_Type.STEAM
	# Show the Steam multiplayer menu
	steam_multiplayer_menu.show()

#-------------------------------------------------------------------------------
# UI (Signalled from their respective menus
#-------------------------------------------------------------------------------
func create_lobby(lobby_name: String, is_private: bool = false, password: String = "") -> void:
	print("Create lobby pressed.")
	network_manager.become_host(lobby_name, is_private, password)

# Lobby ID only set when using Steam
func join_lobby(lobby_id: int = 0) -> void:
	network_manager.join_as_client(lobby_id)

#-------------------------------------------------------------------------------
# Lobbies
#-------------------------------------------------------------------------------
func on_lobby_match_list(lobbies: Array) -> void:
	steam_multiplayer_menu.on_lobby_match_list(lobbies)

func list_steam_lobbies() -> void:
	print("Listing Steam lobbies.")
	network_manager.list_lobbies()

func on_lobby_created() -> void:
	# Hide the multiplayer menu
	if is_using_steam: steam_multiplayer_menu.hide()
	# Set up the lobby menu
	multiplayer_lobby_menu.set_lobby_name_text(network_manager.active_network.lobby_name)
	# Show the lobby menu
	multiplayer_lobby_menu.show()

#-------------------------------------------------------------------------------
# Starting Game
#-------------------------------------------------------------------------------
func start_game() -> void:
	# Load the multiplayer level scene
	var level = multiplayer_level.instantiate()
	# Add it to the level node
	level_node.add_child(level)
	# Hide the lobby menu
	multiplayer_lobby_menu.hide()

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
func on_peer_connected(id: int) -> void:
	print("Player %s connected!" % id)

func on_peer_disconnected(id: int) -> void:
	print("Player %s disconnected!" % id)
	# Remove the player from the players dictionary
	players.erase(id)
	
	# TODO: Remove player from the game

func on_connected_to_server(username: String) -> void: 
	print("Connected to server.")
	# Send connected player's information to the server
	add_player_to_lobby.rpc_id(1, multiplayer.get_unique_id(), username)

func on_connection_failed() -> void: 
	print("Connection failed.")


# To be called on the server
@rpc("any_peer", "call_local")
func add_player_to_lobby(id: int, username: String) -> void:
	# Store the connected player's information
	if !players.has(id):
		players[id] = { 
			"id" : id, 
			"username" : username, 
			"player_num" : players.size() + 1, 
		}
	print("Current player count: %s" % players.size())
	
	# TODO: Update lobby
	multiplayer_lobby_menu.update_player_list(players, players.size())
