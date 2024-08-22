class_name MultiplayerLobbyMenu
extends Control

var player_lobby_display := load("res://Scenes/UI/Menus/Components/player_lobby_display.tscn")
var weapon_select_button_scene := load("res://Scenes/UI/Menus/Components/weapon_select_button.tscn")
# Weapon icons
var rifle_icon := load("res://Assets/UI_Assets/Weapons/Weapons/rifle_icon.png")
var deagle_icon := load("res://Assets/UI_Assets/Weapons/Weapons/deagle_icon.png")
var shotgun_icon := load("res://Assets/UI_Assets/Weapons/Weapons/shotgun_icon.png")
var rocket_launcher_icon := load("res://Assets/UI_Assets/Weapons/Weapons/rocket_launcher_icon.png")
var p90_icon := load("res://Assets/UI_Assets/Weapons/Weapons/P90_icon.png")

# Variables to be injected by/referenced from another script
@export var players : Dictionary = {}
var player_count : int
var readied_player_count : int

# UI elements
@export_group("Players List")
@export var lobby_name_label : Label
@export var player_count_label : Label
@export var player_displays_vbox : VBoxContainer

@export_group("Weapon Selection")
@export var primary_weapon_button : SelectedWeaponButton
@export var primary_weapon_panel : PanelContainer
@export var secondary_weapon_button : SelectedWeaponButton
@export var secondary_weapon_panel : PanelContainer
@export var weapon_grids : Array[GridContainer]
var weapon_names : Array[String] = ["Rifle", "Deagle", "Shotgun", "Rocket Launcher", "P90"]
var default_primary_weapon : String
var default_secondary_weapon : String

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
	
	default_primary_weapon = primary_weapon_button.weapon_name
	default_secondary_weapon = secondary_weapon_button.weapon_name
	primary_weapon_button.text = ""
	secondary_weapon_button.text = ""
	set_weapon_icon(primary_weapon_button, true)
	set_weapon_icon(secondary_weapon_button, true)

# Set name at top to lobby name
func set_lobby_name_text(lobby_name: String) -> void:
	lobby_name_label.text = lobby_name

#-------------------------------------------------------------------------------
# Adding and Removing Players
#-------------------------------------------------------------------------------
func add_player(player_id: int, username: String) -> void:
	print("Add player called.")
	# Create a player display
	var player_display = player_lobby_display.instantiate() as PlayerLobbyDisplay
	# Set the player display data
	player_display.player_name = username
	# Add it to the players list
	player_displays_vbox.add_child(player_display, true)
	# Add the player to the dictionary
	players[player_id] = { 
			"username" : username,
			"player_display" : player_display,
			"ready_status" : false,
			"primary_weapon" : "",
			"secondary_weapon" : "",
		}
	# Update the player's weapons
	update_player_weapons(player_id, default_primary_weapon, default_secondary_weapon)
	# Updated the player count
	player_count += 1
	# Update the player count text
	player_count_label.text = "Players (%s/4)" % player_count
	# Update whether the start button is enabled
	update_start_button_enabled()

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
	# Update whether the start button is enabled
	update_start_button_enabled()

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
			# Set its weapon name to the weapon name
			weapon_select_button.weapon_name = weapon_name
			# Set its icon
			set_weapon_icon(weapon_select_button)
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
	if selected_weapon == secondary_weapon_button.weapon_name:
		secondary_weapon_button.weapon_name = primary_weapon_button.weapon_name
	# Set the primary weapon button to the selected weapon
	primary_weapon_button.weapon_name = selected_weapon
	# Update the player's weapons
	var player_id = multiplayer.get_unique_id()
	update_player_weapons.rpc_id(1, player_id, primary_weapon_button.weapon_name, secondary_weapon_button.weapon_name)
	# Update the selected weapon button's icons
	set_weapon_icon(primary_weapon_button, true)
	set_weapon_icon(secondary_weapon_button, true)
	# Hide the weapon selection panel
	primary_weapon_panel.hide()
	# Show the weapon button
	primary_weapon_button.show()

func on_secondary_weapon_select_button_pressed(button: WeaponSelectButton) -> void:
	# Get the selected weapon
	var selected_weapon = button.weapon_name
	# If the selected weapon is the same as the secondary weapon, swap the primary and secondary weapons
	if selected_weapon == primary_weapon_button.weapon_name:
		primary_weapon_button.weapon_name = secondary_weapon_button.weapon_name
	# Set the secondary weapon button to the selected weapon
	secondary_weapon_button.weapon_name = selected_weapon
	# Update the player's weapons
	var player_id = multiplayer.get_unique_id()
	update_player_weapons.rpc_id(1, player_id, primary_weapon_button.weapon_name, secondary_weapon_button.weapon_name)
	# Update the selected weapon button's icons
	set_weapon_icon(primary_weapon_button, true)
	set_weapon_icon(secondary_weapon_button, true)
	# Hide the weapon selection panel
	secondary_weapon_panel.hide()
	# Show the weapon button
	secondary_weapon_button.show()

func set_weapon_icon(button: Button, is_selected_weapon_button: bool = false) -> void:
	if button.weapon_name == weapon_names[0]:
		button.icon = rifle_icon
	elif button.weapon_name == weapon_names[1]:
		button.icon = deagle_icon
	elif button.weapon_name == weapon_names[2]:
		button.icon = shotgun_icon
	elif button.weapon_name == weapon_names[3]:
		button.icon = rocket_launcher_icon
	elif button.weapon_name == weapon_names[4]:
		button.icon = p90_icon
	# Scale the icon's size
	if !is_selected_weapon_button:
		button.add_theme_constant_override("icon_max_width", roundi(button.icon.get_image().get_width() * 0.2))
	else:
		button.add_theme_constant_override("icon_max_width", roundi(button.icon.get_image().get_width() * 0.4))

# Store each player's selected weapons
@rpc("any_peer", "call_local")
func update_player_weapons(player_id: int, p_name: String, s_name: String) -> void:
	var primary_weapon_name = p_name
	if primary_weapon_name == "Deagle": primary_weapon_name = "Pistol"
	elif primary_weapon_name == "Rocket Launcher": primary_weapon_name = "RocketLauncher"
	var secondary_weapon_name = s_name
	if secondary_weapon_name == "Deagle": secondary_weapon_name = "Pistol"
	elif secondary_weapon_name == "Rocket Launcher": secondary_weapon_name = "RocketLauncher"
	players[player_id].primary_weapon = primary_weapon_name
	players[player_id].secondary_weapon = secondary_weapon_name
	print("Player " + str(player_id) + "'s weapons: " + players[player_id].primary_weapon + " " + players[player_id].secondary_weapon)

#-------------------------------------------------------------------------------
# Readying Up
#-------------------------------------------------------------------------------
func on_ready_button_toggled(is_toggled: bool) -> void:
	# Update the ready button's text
	if is_toggled: ready_button.text = "Unready"
	else: ready_button.text = "Ready"
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
	# Update whether the start button is enabled
	update_start_button_enabled()

#-------------------------------------------------------------------------------
# Starting Game
#-------------------------------------------------------------------------------
func update_start_button_enabled() -> void:
	# Enable the start game button if all players are ready
	if readied_player_count == player_count:
		start_game_button.disabled = false
	else:
		start_game_button.disabled = true

func on_start_game_button_pressed() -> void:
	start_game_requested.emit(players)

#-------------------------------------------------------------------------------
# Returning to Lobby
#-------------------------------------------------------------------------------
func return_to_lobby() -> void:
	# Reset the readied player count
	readied_player_count = 0
	for player_id in players:
		# Reset each player's ready status
		players[player_id].ready_status = false
		# Reset each player's ready status text
		players[player_id].player_display.update_ready_status_text(false)
	# Reset the ready buttons
	reset_ready_button.rpc()
	# Reset the start button
	start_game_button.disabled = true

@rpc("any_peer", "call_local")
func reset_ready_button() -> void:
	ready_button.set_pressed_no_signal(false)
	ready_button.text = "Ready"
