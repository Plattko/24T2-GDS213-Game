class_name SprintPlayerState

extends PlayerState

func enter(_msg : Dictionary = {}):
	#print("Entered Sprint player state.")
	pass

func physics_update(_delta : float):
	# Transition to Downed state
	if player.is_downed or player.is_dead:
		transition.emit("DownedPlayerState")
		return
	# Transition to Air state with jump
	if input.is_jump_just_pressed and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	## Last version
	# Handle movement
	#player.velocity.x = input.direction.x * SPRINT_SPEED
	#player.velocity.z = input.direction.z * SPRINT_SPEED
	#player.move_and_slide()
	
	# Handle movement
	var velocity : Vector3 = set_velocity(input.direction, SPRINT_SPEED)
	player.update_velocity(velocity)
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Idle state
	elif !input.direction:
		transition.emit("IdlePlayerState")
	# Transition to Walk state
	elif input.is_sprint_just_released:
		transition.emit("WalkPlayerState")
	# Handle crouch
	if input.is_crouch_pressed:
		# Transition to Slide state
		if input.is_move_forwards_pressed and player.velocity.length() > 6.0:
			transition.emit("SlidePlayerState")
		# Transition to Crouch state
		else:
			transition.emit("CrouchPlayerState")
