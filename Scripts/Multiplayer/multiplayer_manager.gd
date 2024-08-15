class_name MultiplayerManager
extends Node

var multiplayer_scene = load("res://Scenes/Levels/Testing/steam_multiplayer_testing.tscn")

@export var network_manager : NetworkManager
@export var cur_player_count := 0
var max_players : int = 4

@export_group("Menus")
@export var network_type_ui : Control

@export_subgroup("LAN")
@export var lan_ui : Control
@export var name_line : LineEdit
@export var ip_line : LineEdit

@export_subgroup("Steam")
@export var steam_ui : Control
@export var lobbies_vbox : VBoxContainer

func _ready() -> void:
	#network_manager.multiplayer_manager = self
	pass

#-------------------------------------------------------------------------------
# UI
#-------------------------------------------------------------------------------
func use_steam() -> void:
	print("Using Steam!")
	# Show the Steam UI
	network_type_ui.hide()
	steam_ui.show()
	# Initialise steam
	SteamManager.initialise_steam()
	# Connect the lobby match list signal
	Steam.lobby_match_list.connect(on_lobby_match_list)
	# Set the active network type to Steam
	network_manager.active_network_type = NetworkManager.Multiplayer_Network_Type.STEAM

func use_lan() -> void:
	print("Using LAN!")
	# Show the LAN UI
	network_type_ui.hide()
	lan_ui.show()

func become_host() -> void:
	print("Host Game pressed.")
	#network_manager.become_host()

func join_as_client() -> void:
	print("Join as Client pressed.")
	join_lobby()

func _on_start_game_pressed() -> void:
	# Call start_game on all peers
	start_game.rpc()

func list_steam_lobbies() -> void:
	# Steam only
	print("Listing Steam lobbies.")
	network_manager.list_lobbies()

func get_server_ip(server_ip) -> String:
	# LAN only
	if ip_line.text != "":
		print("Server IP: " + ip_line.text)
		return ip_line.text
	else:
		print("Server IP: " + server_ip)
		return server_ip

#-------------------------------------------------------------------------------
# Lobbies
#-------------------------------------------------------------------------------
func on_lobby_match_list(lobbies: Array) -> void:
	print("Lobby match list called.")
	# Clear the existing lobbies from the list
	for lobby in lobbies_vbox.get_children():
		# Delete the lobby
		lobby.queue_free()
	# Display the new lobbies
	for lobby in lobbies:
		# Get the lobby name
		var lobby_name = Steam.getLobbyData(lobby, "name")
		# Only show lobbies with a name
		if lobby_name != "":
			# Create lobby button
			var lobby_button = Button.new()
			lobby_button.text = lobby_name
			lobby_button.size.x = 600
			lobby_button.add_theme_font_size_override("font_size", 24)
			# NOTE: Can override font, use Steam API tutorial to see how
			lobby_button.name = "Lobby_" + str(lobby)
			lobby_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			# Connect the button to the join_lobby function
			lobby_button.pressed.connect(join_lobby.bind(lobby))
			# Add it to the lobbies VBox
			lobbies_vbox.add_child(lobby_button)

func join_lobby(lobby_id: int = 0) -> void:
	network_manager.join_as_client(lobby_id)

#-------------------------------------------------------------------------------
# Connections
#-------------------------------------------------------------------------------
# Is called on the server and clients when a peer connects to the server
func on_peer_connected(id: int) -> void:
	print("Player " + str(id) + " connected!")

# Is called on the server and clients when someone disconnects
func on_peer_disconnected(id: int) -> void:
	print("Player " + str(id) + " disconnected!")
	# Delete the player
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
	# Remove the player from the players dictionary
	GameManager.players.erase(id)

# Is only called from clients
# If you want to send information from the client to the server, do it from here
func on_connected_to_server(username: String) -> void: 
	print("Connected to server.")
	# Send connected player's information to the server
	add_player_to_lobby.rpc_id(1, multiplayer.get_unique_id(), username)
	print("Added player to lobby from connected to server")

# Is only called from clients
func on_connection_failed() -> void: 
	print("Connection failed.")

#-------------------------------------------------------------------------------
# RPCs
#-------------------------------------------------------------------------------
@rpc("any_peer", "call_local")
func start_game() -> void:
	# Load the scene
	var scene = multiplayer_scene.instantiate()
	# Add it to our tree
	get_tree().root.add_child(scene)
	# Hide the connection menu
	self.visible = false

@rpc("any_peer", "call_local")
func add_player_to_lobby(id: int, username: String) -> void:
	cur_player_count += 1
	print("Current player count: " + str(cur_player_count))
	# Send connected player's information to the server
	send_player_information(id, username, cur_player_count)

## NOTE: Use this if players select weapon loadout before entering game
@rpc("any_peer")
func send_player_information(id: int, username: String, player_num: int) -> void:
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
