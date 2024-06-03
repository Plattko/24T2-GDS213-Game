class_name SprintPlayerState

extends PlayerState

const SPRINT_SPEED = 8.0

func enter(previous_state):
	print("Entered Sprint player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = player.direction.x * SPRINT_SPEED
	player.velocity.z = player.direction.z * SPRINT_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
	
	# Transition to Idle state
	if !player.direction:
		transition.emit("IdlePlayerState")
		return
	
	# Transition to Walk state
	if Input.is_action_just_released("sprint"):
		transition.emit("WalkPlayerState")
		return
	
	if Input.is_action_pressed("crouch"):
		# Transition to Slide state
		if player.velocity.length() > 6.0:
			transition.emit("SlidePlayerState")
		# Transition to Crouch state
		else:
			transition.emit("CrouchPlayerState")
		return
