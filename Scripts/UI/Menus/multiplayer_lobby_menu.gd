class_name MultiplayerLobbyMenu
extends Control

var player_lobby_display := load("res://Scenes/UI/Menus/Components/player_lobby_display.tscn")

# Signals to be injected by/referenced from another script


# UI elements
@export var lobby_name_label : Label
@export var player_count_label : Label
@export var player_displays_vbox : VBoxContainer

@export var ready_button : Button
@export var start_game_button : Button

# Variables to synchronise
@export var player_displays : Array = []
@export var readied_players : int = 0

signal start_game_requested

func _ready() -> void:
	ready_button.toggled.connect(on_ready_button_toggled)
	start_game_button.pressed.connect(on_start_game_button_pressed)

# Set name at top to lobby name
func set_lobby_name_text(lobby_name: String) -> void:
	lobby_name_label.text = lobby_name


# Create player list based on players
func update_player_list(players: Dictionary, player_count: int) -> void:
	print("Update player list called.")
	# Clear the existing player displays from the list
	for player_display in player_displays_vbox.get_children():
		# Delete the player display
		player_display.queue_free()
	# Display the new player list
	for player in players:
		# Create a player display
		var player_display = player_lobby_display.instantiate() as PlayerLobbyDisplay
		# Set the player display data
		player_display.player_name = players[player].username
		# Add it to the players list
		player_displays_vbox.add_child(player_display)
	# Update the player count text
	player_count_label.text = str(player_count) + "/4"




# Weapon select UI functionality




# Store each player's selected weapons




# Store which players are ready
func on_ready_button_toggled(is_toggled: bool) -> void:
	# Updated number of readied players
	if is_toggled:
		readied_players += 1
	else:
		readied_players -= 1
	# Update the player's ready status text
	



# Start game
func on_start_game_button_pressed() -> void:
	start_game_requested.emit()
