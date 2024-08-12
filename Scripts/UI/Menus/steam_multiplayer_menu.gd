class_name SteamMultiplayerMenu
extends Control

@export_group("Find Lobbies")
@export var lobbies_ui : PanelContainer
@export var lobbies_vbox : VBoxContainer
@export var refresh_list_button : Button
@export var join_game_button : Button

@export_group("Create Lobby")
@export var create_game_button : Button
@export var create_lobby_ui : PanelContainer
@export var close_button : Button
@export var lobby_name_line : LineEdit
@export var private_button : Button
@export var password_label : Label
@export var password_line : LineEdit
@export var label_spacer : Panel
@export var input_spacer : Panel
@export var create_button : Button

var lobby_display_scene = load("res://Scenes/UI/Menus/Components/lobby_display.tscn")
var selected_lobby

signal refresh_lobbies_requested()
signal join_lobby_requested(lobby_id: int)
signal create_lobby_requested(lobby_name: String, is_private: bool, password: String)

func _ready() -> void:
	refresh_list_button.pressed.connect(on_refresh_list_button_pressed)
	join_game_button.pressed.connect(on_join_game_button_pressed)
	create_game_button.pressed.connect(on_create_game_button_pressed)
	close_button.pressed.connect(on_close_button_pressed)
	private_button.toggled.connect(on_private_button_toggled)
	password_line.text_changed.connect(on_password_line_text_changed)
	create_button.pressed.connect(on_create_button_pressed)
	
	lobbies_ui.show()
	create_lobby_ui.hide()
	password_label.hide()
	password_line.hide()
	label_spacer.show()
	input_spacer.show()
	private_button.text = ""
	private_button.button_pressed = false

#-------------------------------------------------------------------------------
# Listing Lobbies
#-------------------------------------------------------------------------------
func on_lobby_match_list(lobbies: Array) -> void:
	print("List lobbies called.")
	# Clear the existing lobbies from the list
	for lobby in lobbies_vbox.get_children():
		# Delete the lobby
		lobby.queue_free()
	# Display the new lobbies
	for lobby in lobbies:
		# Create lobby display
		var lobby_display = lobby_display_scene.instantiate() as LobbyDisplay
		# Set the lobby display data
		lobby_display.lobby_name = Steam.getLobbyData(lobby, "lobby_name")
		lobby_display.player_count = Steam.getLobbyData(lobby, "player_count").to_int()
		lobby_display.host_name = Steam.getLobbyData(lobby, "host_name")
		lobby_display.availability = Steam.getLobbyData(lobby, "availability")
		lobby_display.password = Steam.getLobbyData(lobby, "password")
		# Get reference to lobby button
		var lobby_button = lobby_display.button
		# Connect the button to the join_lobby function
		lobby_button.pressed.connect(on_lobby_selected.bind(lobby))
		# Add it to the lobbies VBox
		lobbies_vbox.add_child(lobby_display)

func on_refresh_list_button_pressed() -> void:
	unselect_lobby()
	refresh_lobbies_requested.emit()

#-------------------------------------------------------------------------------
# Joining Lobby
#-------------------------------------------------------------------------------
func on_lobby_selected(lobby) -> void:
	selected_lobby = lobby
	join_game_button.disabled = false

func unselect_lobby() -> void:
	join_game_button.disabled = true

func on_join_game_button_pressed() -> void:
	join_lobby_requested.emit(selected_lobby)

#-------------------------------------------------------------------------------
# Creating Lobby
#-------------------------------------------------------------------------------
func on_create_game_button_pressed() -> void:
	lobbies_ui.hide()
	unselect_lobby()
	lobby_name_line.text = SteamManager.steam_username + "'s Lobby"
	create_lobby_ui.show()

func on_close_button_pressed() -> void:
	create_lobby_ui.hide()
	lobby_name_line.text = ""
	private_button.button_pressed = false
	password_line.text = ""
	lobbies_ui.show()

func on_private_button_toggled(is_toggled: bool) -> void:
	if is_toggled:
		create_button.disabled = true
		private_button.text = "X"
		label_spacer.hide()
		input_spacer.hide()
		password_label.show()
		password_line.show()
	else:
		create_button.disabled = false
		private_button.text = ""
		password_label.hide()
		password_line.hide()
		password_line.text = ""
		label_spacer.show()
		input_spacer.show()

func on_password_line_text_changed(new_text: String) -> void:
	if new_text == "":
		create_button.disabled = true
	else:
		create_button.disabled = false

func on_create_button_pressed() -> void:
	# Set the lobby name to the text in the lobby name line
	var lobby_name = lobby_name_line.text
	# If the lobby name line is empty, default it to Name's Lobby
	if lobby_name == "": lobby_name = SteamManager.steam_username + "'s Lobby"
	# Set the privacy
	var is_private = private_button.button_pressed
	# Set the password
	var password = password_line.text
	# Request a lobby from the multiplayer connection menu
	create_lobby_requested.emit(lobby_name, is_private, password)

