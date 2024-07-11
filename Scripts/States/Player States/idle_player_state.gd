class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 5.0

func enter(_previous_state, _msg : Dictionary = {}):
	#print("Entered Idle player state.")
	pass

func physics_update(delta : float):
	# Transition to Air state with jump
	if (input.is_jump_just_pressed or input.is_jump_buffered) and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Handle deceleration
	#if not MultiplayerManager.is_multiplayer or multiplayer.is_server():
	player.velocity.x = lerp(player.velocity.x, input.direction.x * STOP_SPEED, delta * 7.0)
	player.velocity.z = lerp(player.velocity.z, input.direction.z * STOP_SPEED, delta * 7.0)
	player.move_and_slide()
	
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

