class_name SprintPlayerState

extends PlayerState

const SPRINT_SPEED = 8.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Sprint player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = player.direction.x * SPRINT_SPEED
	player.velocity.z = player.direction.z * SPRINT_SPEED
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif Input.is_action_just_pressed("jump") and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Transition to Idle state
	elif !player.direction:
		transition.emit("IdlePlayerState")
	# Transition to Walk state
	elif Input.is_action_just_released("sprint"):
		transition.emit("WalkPlayerState")
	# Handle crouch
	if Input.is_action_pressed("crouch"):
		# Transition to Slide state
		if Input.is_action_pressed("move_forwards") and player.velocity.length() > 6.0:
			transition.emit("SlidePlayerState")
		# Transition to Crouch state
		else:
			transition.emit("CrouchPlayerState")
