extends Node

var player : CharacterBody3D

func get_direction() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump")
