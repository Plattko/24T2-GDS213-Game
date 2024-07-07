class_name AirPlayerState

extends PlayerState

const JUMP_VELOCITY := 8.0

const WALK_SPEED := 5.0
const SPRINT_SPEED := 8.0
var speed

@export var wallrun_cooldown : Timer

var horizontal_velocity : float:
	get:
		return Vector2(player.velocity.x, player.velocity.z).length()

const WALL_RUN_MIN_SPEED := 5.1

func enter(_previous_state, msg : Dictionary = {}):
	#print("Entered Air player state.")
	# Disable head bob
	player.can_head_bob = false
	
	if msg.has("do_jump"):
		player.velocity.y = JUMP_VELOCITY
	if msg.has("left_wallrun"):
		wallrun_cooldown.start()
		
func exit():
	# Re-enable head bob
	player.can_head_bob = true

func physics_update(delta : float):
	# Apply gravity
	player.update_gravity(delta)
	
	# Set horizontal speed
	if input.is_sprint_pressed:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Handle movement
	player.velocity.x = lerp(player.velocity.x, input.direction.x * speed, delta * 4.0)
	player.velocity.z = lerp(player.velocity.z, input.direction.z * speed, delta * 4.0)
	player.move_and_slide()
	
	# Handle landing
	if player.is_on_floor():
		# Transition to Crouch state
		if player.ceiling_check.is_colliding() == true:
			transition.emit("CrouchPlayerState")
		# Transition to Idle state
		elif !input.direction:
			transition.emit("IdlePlayerState")
		# Transition to Sprint state
		elif input.direction and input.is_sprint_pressed:
			transition.emit("SprintPlayerState")
		# Transition to Walk state
		elif input.direction and !input.is_sprint_pressed:
			transition.emit("WalkPlayerState")
	else:
		# Transition to Wallrun state
		if input.is_jump_just_pressed and player.is_on_wall() and horizontal_velocity > WALL_RUN_MIN_SPEED and wallrun_cooldown.is_stopped():
			transition.emit("WallrunPlayerState")
