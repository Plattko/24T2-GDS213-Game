class_name UIManager
extends Control

@export var hud : HUD
@export var escape_menu : EscapeMenu

func _ready() -> void:
	if not is_multiplayer_authority(): 
		self.queue_free()

func _input(event):
	if event.is_action_pressed("escape"):
		# If options menu is open, go back to escape menu
		if escape_menu.options_menu.is_visible_in_tree():
			escape_menu.options_menu.hide()
			escape_menu.buttons_vbox.show()
		# If escape menu is open, go back to game
		elif escape_menu.is_visible_in_tree():
			escape_menu.close()
		# If escape menu isn't open, open it
		else:
			escape_menu.open()
