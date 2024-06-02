class_name AirPlayerState

extends PlayerState

func enter():
	print("Entered Air player state.")

func physics_update(delta : float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if player.is_on_floor():
		if !direction:
			transition.emit("IdlePlayerState")
		elif direction and Input.is_action_pressed("sprint"):
			transition.emit("SprintPlayerState")
		elif direction and !Input.is_action_pressed("sprint"):
			transition.emit("WalkPlayerState")
		return
