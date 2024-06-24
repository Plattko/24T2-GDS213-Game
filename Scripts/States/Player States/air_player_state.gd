class_name AirPlayerState

extends PlayerState

const JUMP_VELOCITY = 8.0

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
var speed

func enter(previous_state, msg : Dictionary = {}):
	print("Entered Air player state.")
	
	if msg.has("do_jump"):
		player.velocity.y = JUMP_VELOCITY

func physics_update(delta : float):
	# Apply gravity
	player.update_gravity(delta)
	
	# Set horizontal speed
	if input.is_sprint_pressed():
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Handle movement
	player.velocity.x = lerp(player.velocity.x, input.get_direction().x * speed, delta * 4.0)
	player.velocity.z = lerp(player.velocity.z, input.get_direction().z * speed, delta * 4.0)
	player.move_and_slide()
	
	# Handle landing
	if player.is_on_floor():
		# Transition to Crouch state
		if player.ceiling_check.is_colliding() == true:
			transition.emit("CrouchPlayerState")
		# Transition to Idle state
		elif !input.get_direction():
			transition.emit("IdlePlayerState")
		# Transition to Sprint state
		elif input.get_direction() and input.is_sprint_pressed():
			transition.emit("SprintPlayerState")
		# Transition to Walk state
		elif input.get_direction() and !input.is_sprint_pressed():
			transition.emit("WalkPlayerState")
