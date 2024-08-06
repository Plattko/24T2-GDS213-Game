class_name SlidePlayerState

extends PlayerState

# Slide movement variables
#const SLIDE_START_SPEED := 10.0
const SLIDE_START_SPEED : float = 10.5
const SLIDE_END_SPEED : float = 5.0
var slide_direction : Vector3

const SLIDE_DURATION : float = 1.0
var elapsed_time : float = 0.0

# Slide overhaul
var actual_start_speed : float

# Animation variables
const SLIDE_ANIM_SPEED := 14.0

func enter(_msg : Dictionary = {}):
	#print("Entered Slide player state.")
	# Set the slide direction to the player's input
	slide_direction = input.direction
	# Set the slide start speed
	actual_start_speed = maxf(SLIDE_START_SPEED, horizontal_velocity.length())
	# Play the slide animation
	player.play_anim.rpc(player.SLIDE_ANIM, SLIDE_ANIM_SPEED)
	# Disable head bob
	player.can_bob = false

func exit():
	# Reset slide timer
	elapsed_time = 0.0
	# Re-enable head bob
	player.can_bob = true

func physics_update(delta):
	# Transition to Downed state
	if player.is_downed:
		transition.emit("DownedPlayerState", {"left_slide" = true})
		return
	
	if elapsed_time < SLIDE_DURATION:
		## Last version
		# Handle deceleration
		#player.velocity.x = lerp(slide_direction.x * SLIDE_START_SPEED, slide_direction.x * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		#player.velocity.z = lerp(slide_direction.z * SLIDE_START_SPEED, slide_direction.z * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		#player.move_and_slide()
		
		# Handle deceleration
		var velocity : Vector3 = Vector3.ZERO
		velocity.x = lerp(slide_direction.x * actual_start_speed, slide_direction.x * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		velocity.z = lerp(slide_direction.z * actual_start_speed, slide_direction.z * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		player.update_velocity(velocity)
		
		# Increment the slide timer
		elapsed_time += delta
		
		# Transition to Air state
		if !player.is_on_floor():
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
			transition.emit("AirPlayerState")
		# Handle jump
		elif input.is_jump_just_pressed: 
			# If above the player is unobstructed, transition to Air state with jump
			if player.ceiling_check.is_colliding() == false:
				player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
				transition.emit("AirPlayerState", {"do_jump" = true})
			# Else, transition to crouch state
			else:
				transition.emit("CrouchPlayerState", {"left_slide" = true})
	else:
		# Transition to Crouch state
		if input.is_crouch_pressed or player.ceiling_check.is_colliding() == true:
			transition.emit("CrouchPlayerState", {"left_slide" = true})
		# Transition to Idle state
		elif !input.direction:
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("IdlePlayerState")
		# Transition to Walk state
		elif input.direction and !input.is_sprint_pressed:
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("WalkPlayerState")
		# Transition to Sprint state
		elif input.direction and input.is_sprint_pressed:
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("SprintPlayerState")
	
	# Debug
	if debug:
		debug.add_debug_property("Slide Timer", snappedf(elapsed_time, 0.01), 3)
