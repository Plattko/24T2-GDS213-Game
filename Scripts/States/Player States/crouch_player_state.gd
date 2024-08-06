class_name CrouchPlayerState

extends PlayerState

const CROUCH_ANIM_SPEED : float = 7.0

var is_crouch_released : bool = false

func enter(msg : Dictionary = {}) -> void:
	#print("Entered Crouch player state.")
	
	if msg.has("left_slide") or msg.has("left_downed"):
		# Transition to crouch animation from slide or downed animation
		player.seek_anim.rpc(player.CROUCH_ANIM, 1.0)
	else:
		# Play the crouch animation
		player.play_anim.rpc(player.CROUCH_ANIM, CROUCH_ANIM_SPEED)

func exit():
	is_crouch_released = false

func physics_update(_delta) -> void:
	# Transition to Downed state
	if player.is_downed or player.is_dead:
		transition.emit("DownedPlayerState", {"left_crouch" = true})
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
		player.stand_up("CrouchPlayerState", CROUCH_ANIM_SPEED, true)
		transition.emit("AirPlayerState")
	# Transition to Air state with jump
	elif input.is_jump_just_pressed and player.ceiling_check.is_colliding() == false:
		player.stand_up("CrouchPlayerState", CROUCH_ANIM_SPEED, true)
		transition.emit("AirPlayerState", {"do_jump" = true})
	# Handle releasing crouch
	elif input.is_crouch_just_released:
		uncrouch()
	elif !input.is_crouch_pressed and !is_crouch_released:
		is_crouch_released = true
		uncrouch()

func uncrouch() -> void:
	# If there is nothing blocking the player from standing up, play the uncrouch animation
	if !player.ceiling_check.is_colliding() and !input.is_crouch_pressed:
		player.play_anim.rpc(player.CROUCH_ANIM, -CROUCH_ANIM_SPEED, true)
		
		# Wait for uncrouch animation to end
		if player.anim_player.is_playing():
			await player.anim_player.animation_finished
		
		# Transition to Idle state
		if !input.direction:
			transition.emit("IdlePlayerState")
			# Transition to Walk state
		elif input.direction and !input.is_sprint_pressed:
			transition.emit("WalkPlayerState")
		# Transition to Sprint state
		elif input.direction and input.is_sprint_pressed:
			transition.emit("SprintPlayerState")
	
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif player.ceiling_check.is_colliding():
		await get_tree().create_timer(0.1).timeout
		uncrouch()
