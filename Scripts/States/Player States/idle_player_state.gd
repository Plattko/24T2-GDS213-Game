class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 5.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Idle player state.")

func physics_update(delta : float):
	# Handle deceleration
	player.velocity.x = lerp(player.velocity.x, player.direction.x * STOP_SPEED, delta * 7.0)
	player.velocity.z = lerp(player.velocity.z, player.direction.z * STOP_SPEED, delta * 7.0)
	player.move_and_slide()
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
	elif Input.is_action_just_pressed("jump") and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Transition to Crouch state
	if Input.is_action_pressed("crouch"):
		transition.emit("CrouchPlayerState")
		return
	
	# Transition to Walk state
	if player.direction && !Input.is_action_pressed("sprint"):
		transition.emit("WalkPlayerState")
		return
	
	# Transition to Sprint state
	if player.direction && Input.is_action_pressed("sprint"):
		transition.emit("SprintPlayerState")
		return
