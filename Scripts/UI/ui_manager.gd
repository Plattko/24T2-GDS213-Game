extends Control

@onready var settings_menu = %SettingsMenu

func _ready() -> void:
	if not is_multiplayer_authority(): 
		self.queue_free()
		return

func _input(event):
	if event.is_action_pressed("settings_menu"):
		if not settings_menu.visible:
			open_settings_menu()
		else:
			close_settings_menu()

func open_settings_menu() -> void:
	settings_menu.set_process(true)
	settings_menu.open()

func close_settings_menu() -> void:
	settings_menu.close()
