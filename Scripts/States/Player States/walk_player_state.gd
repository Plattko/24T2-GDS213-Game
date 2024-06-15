class_name WalkPlayerState

extends PlayerState

const WALK_SPEED = 5.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Walk player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = input.get_direction().x * WALK_SPEED
	player.velocity.z = input.get_direction().z * WALK_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif input.is_jump_just_pressed() and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Transition to Idle state
	elif !input.get_direction():
		transition.emit("IdlePlayerState")
	# Transition to Crouch state
	elif input.is_crouch_pressed():
		transition.emit("CrouchPlayerState")
	# Transition to Sprint state
	elif input.is_sprint_pressed():
		transition.emit("SprintPlayerState")
