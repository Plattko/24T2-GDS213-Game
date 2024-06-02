class_name WalkPlayerState

extends PlayerState

const WALK_SPEED = 5.0

func enter():
	print("Entered Walk player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = player.direction.x * WALK_SPEED
	player.velocity.z = player.direction.z * WALK_SPEED
	player.move_and_slide()
	
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
	
	if !player.direction:
		transition.emit("IdlePlayerState")
	
	if Input.is_action_pressed("sprint"):
		transition.emit("SprintPlayerState")
		return
