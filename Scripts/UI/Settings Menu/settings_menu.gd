class_name SettingsMenu

extends Control

@export_category("Settings Buttons")
@export var exit_button : Button

signal exit_settings_menu

func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)

func on_exit_pressed():
	exit_settings_menu.emit()
