class_name SettingsMenu

extends Control

signal opened_settings_menu
signal closed_settings_menu

func _ready():
	set_process(false)

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	opened_settings_menu.emit()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed_settings_menu.emit()
	set_process(false)
