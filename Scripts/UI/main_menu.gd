class_name MainMenu
extends Control

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
	play_button.pressed.connect(on_play_button_pressed)
	tutorial_button.pressed.connect(on_tutorial_button_pressed)
	options_button.pressed.connect(on_options_button_pressed)
	credits_button.pressed.connect(on_credits_button_pressed)
	quit_button.pressed.connect(on_quit_button_pressed)
	use_steam_button.pressed.connect(on_use_steam_button_pressed)
	use_lan_button.pressed.connect(on_use_lan_button_pressed)
	
	use_steam_button.hide()
	use_lan_button.hide()

func on_play_button_pressed() -> void:
	use_steam_button.show() if !use_steam_button.is_visible_in_tree() else use_steam_button.hide()
	use_lan_button.show() if !use_lan_button.is_visible_in_tree() else use_lan_button.hide()

func on_tutorial_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()

func on_options_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()

func on_credits_button_pressed() -> void:
	if use_steam_button.is_visible_in_tree(): use_steam_button.hide()
	if use_lan_button.is_visible_in_tree(): use_lan_button.hide()

func on_quit_button_pressed() -> void:
	get_tree().quit()

func on_use_steam_button_pressed() -> void:
	pass

func on_use_lan_button_pressed() -> void:
	pass
