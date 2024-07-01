extends Node
#extends PlayerInput

#var is_server : bool = false
#
#func _ready() -> void:
	#if get_multiplayer_authority() != multiplayer.get_unique_id():
		#is_server = true
#
## --------------------------------MOVEMENT------------------------------------ #
#func get_direction():
	#if not is_server:
		#super()
#
#func is_move_forwards_pressed():
	#if not is_server:
		#super()
#
#func is_jump_just_pressed():
	#if not is_server:
		#super()
#
#func is_sprint_pressed():
	#if not is_server:
		#super()
#
#func is_sprint_just_released():
	#if not is_server:
		#super()
#
#func is_crouch_pressed():
	#if not is_server:
		#super()
#
#func is_crouch_just_released():
	#if not is_server:
		#super()
#
## --------------------------------SHOOTING------------------------------------ #
#func is_shoot_pressed():
	#if not is_server:
		#super()
#
#func is_shoot_just_pressed():
	#if not is_server:
		#super()
#
#func is_reload_pressed():
	#if not is_server:
		#super()
#
#func is_weapon_1_pressed():
	#if not is_server:
		#super()
#
#func is_weapon_2_pressed():
	#if not is_server:
		#super()
#
#func is_weapon_3_pressed():
	#if not is_server:
		#super()
#
## --------------------------------TOGGLES------------------------------------ #
#func on_opened_settings_menu() -> void:
	#if not is_server:
		#super()
#
#func on_closed_settings_menu() -> void:
	#if not is_server:
		#super()
