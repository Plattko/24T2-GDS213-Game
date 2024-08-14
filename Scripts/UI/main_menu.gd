class_name MainMenu
extends Control

var multiplayer_connection_menu := load("res://Scenes/UI/Menus/multiplayer_connection_menu.tscn")

@export_group("Menus")
@export var menu_margin_container : MarginContainer
@export var options_menu : SettingsMenu

@export_group("Buttons")
@export var play_button : Button
@export var tutorial_button : Button
@export var options_button : Button
@export var credits_button : Button
@export var quit_button : Button

@export_subgroup("Play Option Buttons")
@export var use_steam_button : Button
@export var use_lan_button : Button

func _ready() -> void:
	handle_connected_signals()
	use_steam_button.hide()
	use_lan_button.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_play_button_pressed() -> void:
	use_steam_button.show() if !use_steam_button.is_visible_in_tree() else use_steam_button.hide()
	use_lan_button.show() if !use_lan_button.is_visible_in_tree() else use_lan_button.hide()

func on_use_steam_button_pressed() -> void:
	GameManager.is_using_steam = true
	get_tree().change_scene_to_packed(multiplayer_connection_menu)

func on_use_lan_button_pressed() -> void:
	GameManager.is_using_steam = false
	get_tree().change_scene_to_packed(multiplayer_connection_menu)

func on_tutorial_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()

func on_options_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()
	
	menu_margin_container.hide()
	options_menu.show()

func on_exit_options_button_pressed() -> void:
	options_menu.hide()
	menu_margin_container.show()

func on_credits_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()

func on_quit_button_pressed() -> void:
	get_tree().quit()

func handle_connected_signals() -> void:
	play_button.pressed.connect(on_play_button_pressed)
	use_steam_button.pressed.connect(on_use_steam_button_pressed)
	use_lan_button.pressed.connect(on_use_lan_button_pressed)
	tutorial_button.pressed.connect(on_tutorial_button_pressed)
	options_button.pressed.connect(on_options_button_pressed)
	var exit_options_button = options_menu.exit_button
	exit_options_button.pressed.connect(on_exit_options_button_pressed)
	credits_button.pressed.connect(on_credits_button_pressed)
	quit_button.pressed.connect(on_quit_button_pressed)
