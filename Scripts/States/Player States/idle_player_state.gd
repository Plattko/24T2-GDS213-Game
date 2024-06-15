class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 5.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Idle player state.")

func physics_update(delta : float):
	# Handle deceleration
	player.velocity.x = lerp(player.velocity.x, input.get_direction().x * STOP_SPEED, delta * 7.0)
	player.velocity.z = lerp(player.velocity.z, input.get_direction().z * STOP_SPEED, delta * 7.0)
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif input.is_jump_just_pressed() and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Transition to Crouch state
	elif input.is_crouch_pressed():
		transition.emit("CrouchPlayerState")
	# Transition to Walk state
	elif input.get_direction() and !input.is_sprint_pressed():
		transition.emit("WalkPlayerState")
	# Transition to Sprint state
	elif input.get_direction() and input.is_sprint_pressed():
		transition.emit("SprintPlayerState")

