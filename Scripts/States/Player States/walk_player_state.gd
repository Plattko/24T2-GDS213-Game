class_name WalkPlayerState

extends PlayerState

const WALK_SPEED = 5.0

func enter(_previous_state, _msg : Dictionary = {}):
	#print("Entered Walk player state.")
	pass

func physics_update(_delta : float):
	# Transition to Air state with jump
	if (input.is_jump_just_pressed or input.is_jump_buffered) and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Handle movement
	player.velocity.x = input.direction.x * WALK_SPEED
	player.velocity.z = input.direction.z * WALK_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Idle state
	elif !input.direction:
		transition.emit("IdlePlayerState")
	# Transition to Crouch state
	elif input.is_crouch_pressed:
		transition.emit("CrouchPlayerState")
	# Transition to Sprint state
	elif input.is_sprint_pressed:
		transition.emit("SprintPlayerState")
