class_name EscapeMenu
extends Control

@export var options_button : Button
@export var leave_game_button : Button
@export var exit_to_desktop_button : Button

@export var buttons_vbox : VBoxContainer
@export var options_menu : SettingsMenu

signal escape_menu_opened
signal escape_menu_closed

func _ready() -> void:
	options_button.pressed.connect(on_options_button_pressed)
	leave_game_button.pressed.connect(on_leave_game_button_pressed)
	exit_to_desktop_button.pressed.connect(on_exit_to_desktop_button_pressed)
	
	options_menu.disable_input_check()
	options_menu.hide()

#-------------------------------------------------------------------------------
# Opening and Closing
#-------------------------------------------------------------------------------
func open() -> void:
	escape_menu_opened.emit()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	escape_menu_closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()

#-------------------------------------------------------------------------------
# Options Menu
#-------------------------------------------------------------------------------
func on_options_button_pressed() -> void:
	buttons_vbox.hide()
	options_menu.show()

#-------------------------------------------------------------------------------
# Leaving Game (Returning to Main Menu)
#-------------------------------------------------------------------------------
func on_leave_game_button_pressed() -> void:
	multiplayer.multiplayer_peer.close()

#-------------------------------------------------------------------------------
# Exiting to Desktop
#-------------------------------------------------------------------------------
func on_exit_to_desktop_button_pressed() -> void:
	GameManager.is_exiting_to_desktop = true
	multiplayer.multiplayer_peer.close()
	get_tree().quit()

