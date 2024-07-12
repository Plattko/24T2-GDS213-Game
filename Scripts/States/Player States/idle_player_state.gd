class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 7.0

func enter(_msg : Dictionary = {}):
	#print("Entered Idle player state.")
	pass

func physics_update(delta : float):
	# Transition to Air state with jump
	if input.is_jump_just_pressed and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Handle deceleration
	if abs(player.velocity.x) > 0.01: player.velocity.x = lerp(player.velocity.x, 0.0, delta * STOP_SPEED)
	elif abs(player.velocity.x) > 0.0: player.velocity.x = 0.0
	if abs(player.velocity.z) > 0.01: player.velocity.z = lerp(player.velocity.z, 0.0, delta * STOP_SPEED)
	elif abs(player.velocity.z) > 0.0: player.velocity.z = 0.0
	player.move_and_slide()
	
	## TODO: Split into x and z axes
	#if abs(horizontal_velocity.length()) > 0.01:
		#player.update_velocity(lerp_velocity(player.velocity, Vector3.ZERO, STOP_SPEED * delta))
	#elif abs(horizontal_velocity.length()) > 0.0:
		#player.update_velocity(set_velocity(0.0))
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Crouch state
	elif input.is_crouch_pressed:
		transition.emit("CrouchPlayerState")
	# Transition to Walk state
	elif input.direction and !input.is_sprint_pressed:
		transition.emit("WalkPlayerState")
	# Transition to Sprint state
	elif input.direction and input.is_sprint_pressed:
		transition.emit("SprintPlayerState")

