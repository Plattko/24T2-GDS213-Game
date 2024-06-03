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
		return
	elif Input.is_action_just_pressed("jump") and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Transition to Idle state
	if !player.direction:
		transition.emit("IdlePlayerState")
	
	# Transition to Crouch state
	if Input.is_action_pressed("crouch"):
		transition.emit("CrouchPlayerState")
		return
	
	# Transition to Sprint state
	if Input.is_action_pressed("sprint"):
		transition.emit("SprintPlayerState")
		return
