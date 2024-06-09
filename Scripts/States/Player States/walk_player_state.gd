class_name WalkPlayerState

extends PlayerState

const WALK_SPEED = 5.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Walk player state.")

func physics_update(delta : float):
	# Handle movement
	player.velocity.x = player.direction.x * WALK_SPEED
	player.velocity.z = player.direction.z * WALK_SPEED
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
	# Transition to Crouch state
	elif Input.is_action_pressed("crouch"):
		transition.emit("CrouchPlayerState")
	# Transition to Sprint state
	elif Input.is_action_pressed("sprint"):
		transition.emit("SprintPlayerState")
