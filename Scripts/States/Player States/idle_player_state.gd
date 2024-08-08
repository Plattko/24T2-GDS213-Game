class_name IdlePlayerState

extends PlayerState

const STOP_SPEED = 7.0

func enter(msg : Dictionary = {}):
	#print("Entered Idle player state.")
	if msg.has("respawned"):
		player.play_anim.rpc(player.RESPAWN_ANIM)

func physics_update(delta : float):
	# Transition to Downed state
	if player.is_downed or player.is_dead:
		transition.emit("DownedPlayerState")
		return
	# Transition to Air state with jump
	if input.is_jump_just_pressed and player.is_on_floor():
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	## V1
	# Handle deceleration
	#if abs(player.velocity.x) > 0.01: player.velocity.x = lerp(player.velocity.x, 0.0, delta * STOP_SPEED)
	#elif abs(player.velocity.x) > 0.0: player.velocity.x = 0.0
	#if abs(player.velocity.z) > 0.01: player.velocity.z = lerp(player.velocity.z, 0.0, delta * STOP_SPEED)
	#elif abs(player.velocity.z) > 0.0: player.velocity.z = 0.0
	#player.move_and_slide()
	
	## Last version
	#var velocity : Vector3 = player.velocity
	#if abs(velocity.x) > 0.01: 
		#velocity.x = lerp(velocity.x, 0.0, delta * STOP_SPEED)
	#elif abs(velocity.x) > 0.0: 
		#velocity.x = 0.0
	#if abs(velocity.z) > 0.01: 
		#velocity.z = lerp(velocity.z, 0.0, delta * STOP_SPEED)
	#elif abs(velocity.z) > 0.0: 
		#velocity.z = 0.0
	#player.update_velocity(velocity)
	##player.update_velocity(Vector3.ZERO)
	
	# Handle deceleration
	var player_vel : Vector3 = player.velocity
	var lerped_vel : Vector3 = Vector3.ZERO
	
	if abs(player_vel.x) > 0.01: 
		lerped_vel.x = lerp(player_vel.x, 0.0, delta * STOP_SPEED)
	elif abs(player_vel.x) > 0.0: 
		lerped_vel.x = 0.0
	if abs(player_vel.z) > 0.01: 
		lerped_vel.z = lerp(player_vel.z, 0.0, delta * STOP_SPEED)
	elif abs(player_vel.z) > 0.0: 
		lerped_vel.z = 0.0
	
	var target_vel : Vector3 = (lerped_vel - player_vel)
	
	if player.horizontal_knockback == Vector3.ZERO:
		player.update_velocity(lerped_vel)
	else:
		player.update_velocity(target_vel)
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
	# Transition to Crouch state
	elif input.is_crouch_pressed:
		transition.emit("CrouchPlayerState")
	# Transition to Walk state
	elif input.direction and !input.is_sprint_pressed:
		transition.emit("WalkPlayerState")
	# Transition to Sprint state
	elif input.direction and input.is_sprint_pressed:
		transition.emit("SprintPlayerState")

