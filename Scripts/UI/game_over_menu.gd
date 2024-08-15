class_name GameOverMenu
extends Control

var main_menu := load("res://Scenes/UI/Menus/main_menu.tscn")

@export_group("Game Stats")
@export var waves_survived_text : Label
@export var robots_killed_text : Label
@export var zone_swaps_text : Label

@export_group("Buttons")
@export var back_to_lobby_button : Button
@export var main_menu_button : Button

var players_in_menu : Dictionary = {}
var player_count : int = 0
var back_to_lobby_count : int = 0

signal return_to_lobby_requested

func _ready() -> void:
	back_to_lobby_button.toggled.connect(on_back_to_lobby_button_toggled)
	main_menu_button.pressed.connect(on_main_menu_button_pressed)

#-------------------------------------------------------------------------------
# Displaying Game Over Menu
#-------------------------------------------------------------------------------
func init(waves_survived: int, robots_killed: int, zone_swaps: int) -> void:
	# Set the game stats text
	waves_survived_text.text = "Waves Survived: " + str(waves_survived)
	robots_killed_text.text = "Robots Killed: " + str(robots_killed)
	zone_swaps_text.text = "Zone Swaps: " + str(zone_swaps)
	# Set the back to lobby count to 0
	back_to_lobby_count = 0
	# Get a reference to the Multiplayer Connection Menu
	var multiplayer_connection_menu = get_tree().get_first_node_in_group("multiplayer_connection_menu") as MultiplayerConnectionMenu
	# Set the player count to the size of the Multiplayer Connection Menu's players dictionary
	player_count = multiplayer_connection_menu.players.size()
	# Update the back to lobby button text
	update_back_to_lobby_button_text()
	# Set each player's back to lobby status
	for player_id in multiplayer_connection_menu.players:
		players_in_menu[player_id] = { "back_to_lobby_status" : false }

func update_back_to_lobby_button_text() -> void:
	back_to_lobby_button.text = "Back to lobby " + str(back_to_lobby_count) + "/" + str(player_count)

#-------------------------------------------------------------------------------
# Returning to Lobby
#-------------------------------------------------------------------------------
func on_back_to_lobby_button_toggled(is_toggled: bool) -> void:
	update_back_to_lobby_count.rpc_id(1, multiplayer.get_unique_id(), is_toggled)

@rpc("any_peer", "call_local", "reliable")
func update_back_to_lobby_count(player_id: int, is_toggled: bool) -> void:
	# If the back to lobby button is toggled on, increase the count by 1
	if is_toggled: back_to_lobby_count += 1
	# Otherwise, decrease it by 1
	else: back_to_lobby_count -= 1
	# Update the player's back to lobby status
	players_in_menu[player_id].back_to_lobby_status = is_toggled
	# Update the back to lobby button text
	update_back_to_lobby_button_text()
	# Return to the lobby if all players have the button pressed
	if back_to_lobby_count == player_count:
		# Request a return to the lobby
		return_to_lobby_requested.emit()

#-------------------------------------------------------------------------------
# Returning to Main Menu
#-------------------------------------------------------------------------------
func on_main_menu_button_pressed() -> void:
	multiplayer.multiplayer_peer.close()

#-------------------------------------------------------------------------------
# Removing Players
#-------------------------------------------------------------------------------
func remove_player(player_id: int) -> void:
	# Only run if the players are on the menu
	if !visible: return
	# If the player's back to lobby status was true, decrease the back to lobby count by 1
	if players_in_menu[player_id].back_to_lobby_status == true: back_to_lobby_count -= 1
	# Update the player count
	player_count -= 1
	# Update the back to lobby button text
	update_back_to_lobby_button_text()
