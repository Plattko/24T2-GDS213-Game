class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 5.0

func enter():
	print("Entered Idle player state.")

func physics_update(delta : float):
	# Handle deceleration
	player.velocity.x = lerp(player.velocity.x, player.direction.x * STOP_SPEED, delta * 7.0)
	player.velocity.z = lerp(player.velocity.z, player.direction.z * STOP_SPEED, delta * 7.0)
	player.move_and_slide()
	
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
	
	if player.direction:
		transition.emit("WalkPlayerState")
