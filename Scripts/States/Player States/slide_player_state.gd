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

func enter():
	print("Entered Slide player state.")
	# Reset slide timer
	elapsed_time = 0.0
	slide_direction = -player.transform.basis.z

func physics_update(delta):
	if elapsed_time < SLIDE_DURATION:
		# Handle deceleration
		player.velocity.x = lerp(slide_direction.x * SLIDE_START_SPEED, slide_direction.x * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		player.velocity.z = lerp(slide_direction.z * SLIDE_START_SPEED, slide_direction.z * SLIDE_END_SPEED, elapsed_time / SLIDE_DURATION)
		player.move_and_slide()
		
		# Increment the timer
		elapsed_time += delta
	else:
		transition.emit("IdlePlayerState")
		return
	
	# Transition to Air state
	if !player.is_on_floor():
		transition.emit("AirPlayerState")
		return
