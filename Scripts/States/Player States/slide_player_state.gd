class_name SlidePlayerState

extends PlayerState

# Slide movement variables
#const SLIDE_START_SPEED := 10.0
const SLIDE_START_SPEED := 10.5
const SLIDE_END_SPEED := 5.0
var slide_direction : Vector3

const SLIDE_DURATION := 1.0
var elapsed_time := 0.0

# Animation variables
const SLIDE_ANIM_SPEED := 14.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Slide player state.")
	# Set the slide direction to the direction the player is looking
	#slide_direction = -player.transform.basis.z
	slide_direction = input.get_direction()
	# Play the crouch animation
	player.animation_player.play("Slide", -1, SLIDE_ANIM_SPEED)
	# Disable head bob
	player.can_head_bob = false

func exit():
	# Reset slide timer
	elapsed_time = 0.0
	# Re-enable head bob
	player.can_head_bob = true

func physics_update(delta):
	if elapsed_time < SLIDE_DURATION:
		# Handle deceleration
		player.velocity.x = lerp(slide_direction.x * SLIDE_START_SPEED, slide_direction.x * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		player.velocity.z = lerp(slide_direction.z * SLIDE_START_SPEED, slide_direction.z * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		player.move_and_slide()
		
		# Increment the slide timer
		elapsed_time += delta
		
		# Transition to Air state
		if !player.is_on_floor():
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
			transition.emit("AirPlayerState")
		# Handle jump
		elif input.is_jump_just_pressed(): 
			# If above the player is unobstructed, transition to Air state with jump
			if player.ceiling_check.is_colliding() == false:
				player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
				transition.emit("AirPlayerState", {"do_jump" = true})
			# Else, transition to crouch state
			else:
				transition.emit("CrouchPlayerState")
	else:
		# Transition to Crouch state
		if input.is_crouch_pressed() or player.ceiling_check.is_colliding() == true:
			transition.emit("CrouchPlayerState")
		# Transition to Idle state
		elif !input.get_direction():
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("IdlePlayerState")
		# Transition to Walk state
		elif input.get_direction() and !input.is_sprint_pressed():
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("WalkPlayerState")
		# Transition to Sprint state
		elif input.get_direction() and input.is_sprint_pressed():
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("SprintPlayerState")
	
	# Debug
	Global.debug.add_debug_property("Slide Timer", snappedf(elapsed_time, 0.01), 4)
