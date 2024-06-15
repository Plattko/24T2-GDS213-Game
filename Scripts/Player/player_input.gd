class_name PlayerInput

extends Node

var player : CharacterBody3D

# --------------------------------MOVEMENT------------------------------------ #
func get_direction() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func is_move_forwards_pressed() -> bool:
	return Input.is_action_pressed("move_forwards")

func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")

func is_sprint_just_released() -> bool:
	return Input.is_action_just_released("sprint")

func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

func is_crouch_just_released() -> bool:
	return Input.is_action_just_released("crouch")

# --------------------------------SHOOTING------------------------------------ #
func is_shoot_pressed() -> bool:
	return Input.is_action_pressed("shoot")

func is_shoot_just_pressed() -> bool:
	return Input.is_action_just_pressed("shoot")

func is_reload_pressed() -> bool:
	return Input.is_action_pressed("reload")

func is_weapon_1_pressed() -> bool:
	return Input.is_action_pressed("weapon_1")

func is_weapon_2_pressed() -> bool:
	return Input.is_action_pressed("weapon_2")

func is_weapon_3_pressed() -> bool:
	return Input.is_action_pressed("weapon_3")
