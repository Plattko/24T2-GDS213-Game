class_name PlayerInput

extends Node

var player : CharacterBody3D

var can_move : bool = true
var can_shoot : bool = true
var can_look : bool = true

# --------------------------------MOVEMENT------------------------------------ #
func get_direction() -> Vector3:
	if can_move:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
		return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	return Vector3.ZERO

func is_move_forwards_pressed() -> bool:
	if can_move:
		return Input.is_action_pressed("move_forwards")
	return false

func is_jump_just_pressed() -> bool:
	if can_move:
		return Input.is_action_just_pressed("jump")
	return false

func is_sprint_pressed() -> bool:
	if can_move:
		return Input.is_action_pressed("sprint")
	return false

func is_sprint_just_released() -> bool:
	if can_move:
		return Input.is_action_just_released("sprint")
	return false

func is_crouch_pressed() -> bool:
	if can_move:
		return Input.is_action_pressed("crouch")
	return false

func is_crouch_just_released() -> bool:
	if can_move:
		return Input.is_action_just_released("crouch")
	return false

# --------------------------------SHOOTING------------------------------------ #
func is_shoot_pressed() -> bool:
	if can_shoot:
		return Input.is_action_pressed("shoot")
	return false

func is_shoot_just_pressed() -> bool:
	if can_shoot:
		return Input.is_action_just_pressed("shoot")
	return false

func is_reload_pressed() -> bool:
	if can_shoot:
		return Input.is_action_pressed("reload")
	return false

func is_weapon_1_pressed() -> bool:
	if can_shoot:
		return Input.is_action_pressed("weapon_1")
	return false

func is_weapon_2_pressed() -> bool:
	if can_shoot:
		return Input.is_action_pressed("weapon_2")
	return false

func is_weapon_3_pressed() -> bool:
	if can_shoot:
		return Input.is_action_pressed("weapon_3")
	return false

# --------------------------------TOGGLES------------------------------------ #
func on_opened_settings_menu() -> void:
	print("Disabled input.")
	can_move = false
	can_shoot = false
	can_look = false

func on_closed_settings_menu() -> void:
	print("Enabled input.")
	can_move = true
	can_shoot = true
	can_look = true
