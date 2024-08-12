class_name MultiplayerLobbyMenu
extends Control

var player_lobby_display := load("res://Scenes/UI/Menus/Components/player_lobby_display.tscn")
var weapon_select_button_scene := load("res://Scenes/UI/Menus/Components/weapon_select_button.tscn")

# Variables to be injected by/referenced from another script
var players : Dictionary = {}
var player_count : int
var readied_player_count : int

# UI elements
@export_group("Players List")
@export var lobby_name_label : Label
@export var player_count_label : Label
@export var player_displays_vbox : VBoxContainer

@export_group("Weapon Selection")
@export var primary_weapon_button : Button
@export var primary_weapon_panel : PanelContainer
@export var secondary_weapon_button : Button
@export var secondary_weapon_panel : PanelContainer
@export var weapon_grids : Array[GridContainer]
var weapon_names : Array[String] = ["Rifle", "Deagle", "Shotgun", "Rocket Launcher", "P90"]

@export_group("Game Start Buttons")
@export var ready_button : Button
@export var start_game_button : Button

signal start_game_requested(_players: Dictionary)

func _ready() -> void:
	spawn_weapon_select_buttons()
	primary_weapon_button.pressed.connect(on_primary_weapon_button_pressed)
	secondary_weapon_button.pressed.connect(on_secondary_weapon_button_pressed)
	primary_weapon_panel.mouse_exited.connect(on_primary_weapon_panel_mouse_exited)
	secondary_weapon_panel.mouse_exited.connect(on_secondary_weapon_panel_mouse_exited)
	
	ready_button.toggled.connect(on_ready_button_toggled)
	start_game_button.pressed.connect(on_start_game_button_pressed)
	
	primary_weapon_panel.hide()
	secondary_weapon_panel.hide()
	primary_weapon_button.show()
	secondary_weapon_button.show()

# Set name at top to lobby name
func set_lobby_name_text(lobby_name: String) -> void:
	lobby_name_label.text = lobby_name


func add_player(player_id: int, username: String) -> void:
	print("Add player called.")
	# Create a player display
	var player_display = player_lobby_display.instantiate() as PlayerLobbyDisplay
	# Set the player display data
	player_display.player_name = username
	# Add it to the players list
	player_displays_vbox.add_child(player_display)
	# Add the player to the dictionary
	players[player_id] = { 
			"player_display" : player_display,
			"ready_status" : false,
			"primary_weapon" : primary_weapon_button.text,
			"secondary_weapon" : secondary_weapon_button.text,
		}
	# Updated the player count
	player_count += 1
	# Update the player count text
	player_count_label.text = "Players (%s/4)" % player_count

func remove_player(player_id: int) -> void:
	print("Remove player called.")
	# Delete the player's player display
	players[player_id].player_display.queue_free()
	# Update the readied players count
	if players[player_id].ready_status == true: readied_player_count -= 1
	# Delete the player from the dictionary
	players.erase(player_id)
	# Update the player count
	player_count -= 1
	# Update the player count text
	player_count_label.text = "Players (%s/4)" % player_count

#-------------------------------------------------------------------------------
# Weapon Selection
#-------------------------------------------------------------------------------
func spawn_weapon_select_buttons() -> void:
	# Spawn the weapon select buttons in each weapon grid
	for weapon_grid in weapon_grids:
		# Iterate through the weapon names and spawn a button for each one
		for weapon_name in weapon_names:
			# Create the weapon select button
			var weapon_select_button = weapon_select_button_scene.instantiate() as WeaponSelectButton
			# Set its name to the weapon name
			weapon_select_button.weapon_name = weapon_name
			# Connect it to the correct weapon select button pressed function
			if weapon_grid == weapon_grids[0]: 
				weapon_select_button.weapon_select_button_pressed.connect(on_primary_weapon_select_button_pressed)
			else: 
				weapon_select_button.weapon_select_button_pressed.connect(on_secondary_weapon_select_button_pressed)
			# Add it as a child of the grid
			weapon_grid.add_child(weapon_select_button)

func on_primary_weapon_button_pressed() -> void:
	primary_weapon_button.hide()
	primary_weapon_panel.show()

func on_secondary_weapon_button_pressed() -> void:
	secondary_weapon_button.hide()
	secondary_weapon_panel.show()

func on_primary_weapon_panel_mouse_exited() -> void:
	primary_weapon_panel.hide()
	primary_weapon_button.show()

func on_secondary_weapon_panel_mouse_exited() -> void:
	secondary_weapon_panel.hide()
	secondary_weapon_button.show()

func on_primary_weapon_select_button_pressed(button: WeaponSelectButton) -> void:
	# Get the selected weapon
	var selected_weapon = button.weapon_name
	# If the selected weapon is the same as the secondary weapon, swap the primary and secondary weapons
	if selected_weapon == secondary_weapon_button.text:
		secondary_weapon_button.text = primary_weapon_button.text
	# Set the primary weapon button to the selected weapon
	primary_weapon_button.text = selected_weapon
	# Update the player's weapons
	var player_id = multiplayer.get_unique_id()
	update_player_weapons.rpc_id(1, player_id)
	# Hide the weapon selection panel
	primary_weapon_panel.hide()
	# Show the weapon button
	primary_weapon_button.show()

func on_secondary_weapon_select_button_pressed(button: WeaponSelectButton) -> void:
	# Get the selected weapon
	var selected_weapon = button.weapon_name
	# If the selected weapon is the same as the secondary weapon, swap the primary and secondary weapons
	if selected_weapon == primary_weapon_button.text:
		primary_weapon_button.text = secondary_weapon_button.text
	# Set the secondary weapon button to the selected weapon
	secondary_weapon_button.text = selected_weapon
	# Update the player's weapons
	var player_id = multiplayer.get_unique_id()
	update_player_weapons.rpc_id(1, player_id)
	# Hide the weapon selection panel
	secondary_weapon_panel.hide()
	# Show the weapon button
	secondary_weapon_button.show()

# Store each player's selected weapons
@rpc("any_peer", "call_local")
func update_player_weapons(player_id: int) -> void:
	var primary_weapon_name = primary_weapon_button.text
	if primary_weapon_name == "Rocket Launcher": primary_weapon_name = "RocketLauncher"
	var secondary_weapon_name = secondary_weapon_button.text
	if secondary_weapon_name == "Rocket Launcher": secondary_weapon_name = "RocketLauncher"
	players[player_id].primary_weapon = primary_weapon_name
	players[player_id].secondary_weapon = secondary_weapon_name

#-------------------------------------------------------------------------------
# Readying Up
#-------------------------------------------------------------------------------
func on_ready_button_toggled(is_toggled: bool) -> void:
	# Update the readied players on the server
	update_readied_players.rpc_id(1, multiplayer.get_unique_id(), is_toggled)

@rpc("any_peer", "call_local", "reliable")
func update_readied_players(player_id: int, is_ready: bool) -> void:
	# Updated number of readied players
	if is_ready:
		readied_player_count += 1
	else:
		readied_player_count -= 1
	# Update the player's ready status
	players[player_id].ready_status = is_ready
	# Update the player's ready status text
	players[player_id].player_display.update_ready_status_text(is_ready)
	# Enable the start game button if all players are ready
	if readied_player_count == player_count:
		start_game_button.disabled = false
	else:
		start_game_button.disabled = true

#-------------------------------------------------------------------------------
# Starting Game
#-------------------------------------------------------------------------------
func on_start_game_button_pressed() -> void:
	start_game_requested.emit(players)
