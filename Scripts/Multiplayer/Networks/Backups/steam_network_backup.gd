extends Node

var multiplayer_manager : MultiplayerManager

var hosted_lobby_id : int = 0
var lobby_name : String = "BWOB"

var multiplayer_peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _ready() -> void:
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
	# Handle connections
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined.bind())
	# Create the lobby
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, multiplayer_manager.max_players)

func join_as_client(lobby_id: int) -> void:
	print("Joining lobby " + str(lobby_id) + ".")
	# Handle connections
	Steam.lobby_joined.connect(on_lobby_joined.bind())
	# Join the lobby
	Steam.joinLobby(lobby_id)

func on_lobby_created(_connect: int, lobby_id: int) -> void:
	# Ignore the signal if connect is anything other than 1
	if _connect == 1:
		hosted_lobby_id = lobby_id
		print("Created lobby: " + str(hosted_lobby_id))
		# Make the lobby joinable
		Steam.setLobbyJoinable(hosted_lobby_id, true)
		# Set the lobby name
		# TODO: Make the player choose this
		Steam.setLobbyData(hosted_lobby_id, "name", lobby_name)
		Steam.setLobbyData(hosted_lobby_id, "player_count", str(multiplayer_manager.cur_player_count))
		Steam.setLobbyData(hosted_lobby_id, "host_name", SteamManager.steam_username)
		
		create_host()

func create_host() -> void:
	print("Create host called.")
	var error = multiplayer_peer.create_host(0, [])
	if error == OK:
			# Establish the host as a multiplayer peer
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		# Pass in the host's player information
		multiplayer_manager.add_player_to_lobby(multiplayer.get_unique_id(), SteamManager.steam_username)
		print("Added player to lobby from Steam network")
	else:
		print("Error creating host: " + str(error))

func on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("On lobby joined called.")
	# If response is 1, we have a successful connection to the lobby
	if response == 1:
		var owner_id = Steam.getLobbyOwner(lobby_id)
		# Check if the player joining is not the host
		if Steam.getSteamID() != owner_id:
			print("Connecting client to socket...")
			# Establish a network connection so we can communicate game data between the host and client
			connect_socket(owner_id)
		else:
			print("Steam ID is owner ID.")
	else:
		# Get the fail reason
		var FAIL_REASON : String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)

func connect_socket(steam_id: int) -> void:
	var error = multiplayer_peer.create_client(steam_id, 0, [])
	if error == OK:
		print("Connecting peer to host...")
		multiplayer.set_multiplayer_peer(multiplayer_peer)
	else:
		print("Error creating client: " + str(error))

func list_lobbies() -> void:
	# Set the distance filter for the lobby list
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	# Add a filter on the lobby names
	Steam.addRequestLobbyListStringFilter("name", "BWOB", Steam.LOBBY_COMPARISON_EQUAL)
	# Request the list of lobbies
	Steam.requestLobbyList()

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
func on_peer_connected(id: int) -> void:
	multiplayer_manager.on_peer_connected(id)

func on_peer_disconnected(id: int) -> void:
	multiplayer_manager.on_peer_disconnected(id)

func on_connected_to_server() -> void:
	multiplayer_manager.on_connected_to_server(SteamManager.steam_username)

func on_connection_failed() -> void: 
	multiplayer_manager.on_connection_failed()