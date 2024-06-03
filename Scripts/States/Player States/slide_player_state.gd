class_name SlidePlayerState

extends PlayerState

# Slide movement variables
const SLIDE_START_SPEED := 10.0
const SLIDE_END_SPEED := 5.0
var slide_direction : Vector3

const SLIDE_DURATION := 1.0
var elapsed_time := 0.0

# Animation variables
const SLIDE_ANIM_SPEED := 14.0

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Slide player state.")
	# Set the slide direction to the direction the player is looking
	slide_direction = -player.transform.basis.z
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
		
		# Increment the timer
		elapsed_time += delta
	else:
		# Transition to Crouch state
		if Input.is_action_pressed("crouch") or player.crouch_shape_cast.is_colliding() == true:
			transition.emit("CrouchPlayerState")
			return
		# Transition to Idle state
		elif !player.direction:
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("IdlePlayerState")
			return
		# Transition to Walk state
		elif player.direction && !Input.is_action_pressed("sprint"):
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("WalkPlayerState")
			return
		# Transition to Sprint state
		elif player.direction && Input.is_action_pressed("sprint"):
			player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, false)
			transition.emit("SprintPlayerState")
			return
	
	# Transition to Air state
	if !player.is_on_floor():
		player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
		transition.emit("AirPlayerState")
		return
	elif Input.is_action_just_pressed("jump") and player.crouch_shape_cast.is_colliding() == false:
		player.stand_up("SlidePlayerState", SLIDE_ANIM_SPEED, true)
		transition.emit("AirPlayerState", {"do_jump" = true})
		return
	
	# Debug
	Global.debug.add_debug_property("Slide Timer", snappedf(elapsed_time, 0.01), 4)
