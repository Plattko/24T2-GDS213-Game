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
	
	## Last version
	# Handle deceleration
	#if abs(player.velocity.x) > 0.01: player.velocity.x = lerp(player.velocity.x, 0.0, delta * STOP_SPEED)
	#elif abs(player.velocity.x) > 0.0: player.velocity.x = 0.0
	#if abs(player.velocity.z) > 0.01: player.velocity.z = lerp(player.velocity.z, 0.0, delta * STOP_SPEED)
	#elif abs(player.velocity.z) > 0.0: player.velocity.z = 0.0
	#player.move_and_slide()
	
	# Handle deceleration
	var velocity : Vector3 = player.velocity
	if abs(velocity.x) > 0.01: 
		velocity.x = lerp(velocity.x, 0.0, delta * STOP_SPEED)
	elif abs(velocity.x) > 0.0: 
		velocity.x = 0.0
	if abs(velocity.z) > 0.01: 
		velocity.z = lerp(velocity.z, 0.0, delta * STOP_SPEED)
	elif abs(velocity.z) > 0.0: 
		velocity.z = 0.0
	player.update_velocity(velocity)
	
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

