class_name MultiplayerConnectionMenu
extends Control

var multiplayer_level := load("res://Scenes/Levels/Testing/steam_multiplayer_testing.tscn")
#var multiplayer_level := load("res://Scenes/Levels/playtest_level_wk10.tscn")

@export_group("Network Management")
@export var network_manager : NetworkManager
var is_using_steam : bool = false

@export_group("Menus")
@export var steam_multiplayer_menu : SteamMultiplayerMenu
@export var lan_multiplayer_menu : LANMultiplayerMenu
@export var multiplayer_lobby_menu : MultiplayerLobbyMenu

@export_group("Level")
@export var level_node : Node

# Player Variables
var max_players : int = 4
var players : Dictionary = {}

func _ready() -> void:
	network_manager.multiplayer_connection_menu = self
	
	is_using_steam = GameManager.is_using_steam
	if is_using_steam:
		use_steam()
		steam_multiplayer_menu.refresh_lobbies_requested.connect(list_steam_lobbies)
		steam_multiplayer_menu.join_lobby_requested.connect(join_lobby)
		steam_multiplayer_menu.create_lobby_requested.connect(create_lobby)
	else:
		use_lan()
		lan_multiplayer_menu.join_lobby_requested.connect(join_lobby)
		lan_multiplayer_menu.create_lobby_requested.connect(create_lobby)
	
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

func use_lan() -> void:
	print("Using LAN!")
	# Show the LAN multiplayer menu
	lan_multiplayer_menu.show()

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

# Called by the Steam Network script
func on_lobby_created() -> void:
	print("Lobby created.")
	# Hide the multiplayer menu
	if is_using_steam: steam_multiplayer_menu.hide()
	else: lan_multiplayer_menu.hide()
	# Set up the lobby menu
	multiplayer_lobby_menu.set_lobby_name_text(network_manager.active_network.lobby_name)
	# Show the lobby menu
	multiplayer_lobby_menu.show()

# Called by the Steam Network script
func on_lobby_joined() -> void:
	print("Lobby joined.")

# To be called on the server
@rpc("any_peer", "call_local")
func add_player_to_lobby(id: int, username: String) -> void:
	print("Player %s added to lobby." % id)
	# Store the connected player's information
	if !players.has(id):
		players[id] = { 
			"id" : id, 
			"username" : username, 
			"player_num" : players.size() + 1, 
		}
	print("Current player count: %s" % players.size())
	# Add the player to the lobby
	multiplayer_lobby_menu.add_player(id, username)

func remove_player_from_lobby(id: int) -> void:
	print("Player %s removed from lobby." % id)
	# Remove the player from the lobby
	multiplayer_lobby_menu.remove_player(id)

#-------------------------------------------------------------------------------
# Starting Game
#-------------------------------------------------------------------------------
func start_game(_players: Dictionary) -> void:
	if is_using_steam:
		# Make the lobby not joinable
		network_manager.active_network.set_lobby_joinable(false)
	# Load the multiplayer level scene
	var level = multiplayer_level.instantiate() as SceneManager
	# Add it to the level node
	level_node.add_child(level)
	# Hide the lobby menu
	multiplayer_lobby_menu.hide()
	# Spawn the players
	level.spawn_players(_players)
	# Connect to the game over menu's return to lobby signal
	level.game_over_menu.return_to_lobby_requested.connect(return_to_lobby)

#-------------------------------------------------------------------------------
# Returning to Lobby
#-------------------------------------------------------------------------------
func return_to_lobby() -> void:
	# Delete the level
	level_node.get_child(0).queue_free()
	# Call return to lobby on the lobby menu script
	multiplayer_lobby_menu.return_to_lobby()
	# Show the lobby menu
	multiplayer_lobby_menu.show()

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
func on_peer_connected(id: int) -> void:
	print("Player %s connected!" % id)

func on_peer_disconnected(id: int) -> void:
	print("Player %s disconnected!" % id)
	# Only run as the server
	if !multiplayer.is_server(): return
	# Remove the player from the lobby
	remove_player_from_lobby(id)
	# Get a reference to the level
	var level = get_tree().get_first_node_in_group("level") as SceneManager
	# If there is a level, remove the player from it
	if level: level.remove_player(id)
	# Remove the player from the players dictionary
	players.erase(id)

func on_connected_to_server(username: String) -> void: 
	print("Connected to server.")
	# Send connected player's information to the server
	add_player_to_lobby.rpc_id(1, multiplayer.get_unique_id(), username)

func on_connection_failed() -> void: 
	print("Connection failed.")

func on_server_disconnected() -> void:
	print("Disconnected from server.")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_packed(GameManager.main_menu)
