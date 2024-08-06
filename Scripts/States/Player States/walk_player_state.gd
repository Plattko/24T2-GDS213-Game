class_name WalkPlayerState

extends PlayerState

func enter(_msg : Dictionary = {}):
	#print("Entered Walk player state.")
	pass

func physics_update(_delta : float):
	# Transition to Downed state
	if player.is_downed:
		transition.emit("DownedPlayerState")
		return
	# Transition to Air state with jump
	if input.is_jump_just_pressed and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	## Last version
	# Handle movement
	#player.velocity.x = input.direction.x * WALK_SPEED
	#player.velocity.z = input.direction.z * WALK_SPEED
	#player.move_and_slide()
	
	# Handle movement
	var velocity : Vector3 = set_velocity(input.direction, WALK_SPEED)
	player.update_velocity(velocity)
	
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
