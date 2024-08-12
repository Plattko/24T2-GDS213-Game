class_name MultiplayerConnectionMenu
extends Control

@export var multiplayer_manager : MultiplayerManager
@export var network_manager : NetworkManager
@export var steam_multiplayer_menu : SteamMultiplayerMenu

@export var is_using_steam : bool = false

func _ready() -> void:
	if is_using_steam:
		use_steam()
		steam_multiplayer_menu.refresh_lobbies_requested.connect(list_steam_lobbies)
		steam_multiplayer_menu.join_lobby_requested.connect(join_lobby)
		steam_multiplayer_menu.show()

func use_steam() -> void:
	print("Using Steam!")
	# Initialise steam
	SteamManager.initialise_steam()
	# Connect the lobby match list signal
	Steam.lobby_match_list.connect(on_lobby_match_list)
	# Set the active network type to Steam
	network_manager.active_network_type = NetworkManager.Multiplayer_Network_Type.STEAM

#-------------------------------------------------------------------------------
# Lobbies
#-------------------------------------------------------------------------------
func on_lobby_match_list(lobbies: Array) -> void:
	steam_multiplayer_menu.on_lobby_match_list(lobbies)

func list_steam_lobbies() -> void:
	print("Listing Steam lobbies.")
	network_manager.list_lobbies()

func join_lobby(lobby_id: int = 0) -> void:
	network_manager.join_as_client(lobby_id)
