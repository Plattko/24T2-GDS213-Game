class_name SettingsMenu
extends Control

signal options_menu_closed

func _input(event) -> void:
	if event.is_action_pressed("escape"):
		# If options menu is open, go back to main menu
		if is_visible_in_tree():
			options_menu_closed.emit()

# Called by escape menu
func disable_input_check() -> void:
	set_process_input(false)
