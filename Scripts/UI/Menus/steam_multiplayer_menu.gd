class_name SteamMultiplayerMenu
extends Control

@export_group("Find Lobbies")
@export var lobbies_ui : PanelContainer
@export var lobbies_vbox : VBoxContainer
@export var refresh_list_button : Button
@export var join_button : Button

@export_group("Create Lobby")
@export var create_button : Button
@export var create_lobby_ui : PanelContainer
@export var close_button : Button
@export var lobby_name_line : LineEdit
@export var private_button : Button
@export var password_label : Label
@export var password_line : LineEdit
@export var label_spacer : Panel
@export var input_spacer : Panel

var lobby_display = load("res://Scenes/UI/Menus/Components/lobby_display.tscn")
var selected_lobby

signal refresh_lobbies_requested()
signal join_lobby_requested(lobby_id: int)

func _ready() -> void:
	refresh_list_button.pressed.connect(on_refresh_list_button_pressed)
	create_button.pressed.connect(on_create_button_pressed)
	close_button.pressed.connect(on_close_button_pressed)
	private_button.toggled.connect(on_private_button_toggled)
	
	lobbies_ui.show()
	create_lobby_ui.hide()
	password_label.hide()
	password_line.hide()
	label_spacer.show()
	input_spacer.show()
	private_button.text = ""
	private_button.button_pressed = false

# Show lobbies
func on_lobby_match_list(lobbies: Array) -> void:
	print("List lobbies called.")
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
			# Create lobby display
			var _lobby_display = lobby_display.instantiate()
			# Get reference to lobby button
			var lobby_button = _lobby_display.button
			# Connect the button to the join_lobby function
			lobby_button.pressed.connect(on_lobby_selected.bind(lobby))
			# Add it to the lobbies VBox
			lobbies_vbox.add_child(_lobby_display)



# Refresh lobbies
func on_refresh_list_button_pressed() -> void:
	unselect_lobby()
	refresh_lobbies_requested.emit()



# Click on lobby and click join game to join lobby
func on_lobby_selected(lobby) -> void:
	selected_lobby = lobby
	join_button.disabled = false

func unselect_lobby() -> void:
	join_button.disabled = true

func join_lobby() -> void:
	join_lobby_requested.emit(selected_lobby)

# Click create lobby to show create lobby menu
func on_create_button_pressed() -> void:
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
		private_button.text = "X"
		label_spacer.hide()
		input_spacer.hide()
		password_label.show()
		password_line.show()
	else:
		private_button.text = ""
		password_label.hide()
		password_line.hide()
		label_spacer.show()
		input_spacer.show()

