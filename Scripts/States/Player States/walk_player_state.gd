class_name WalkPlayerState

extends PlayerState

func enter():
	print("Entered Walk player state.")

func physics_update(delta : float):
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if !direction:
		transition.emit("IdlePlayerState")
	
	if Input.is_action_pressed("sprint"):
		transition.emit("SprintPlayerState")
		return
