class_name SettingsMenu
extends Control

@export var exit_button : Button

@export var is_on_main_menu : bool = false

signal opened_settings_menu
signal closed_settings_menu

func _ready():
	if !is_on_main_menu: 
		exit_button.pressed.connect(close)
		set_process(false)

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened_settings_menu.emit()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed_settings_menu.emit()
	set_process(false)
