class_name AirPlayerState

extends PlayerState

const JUMP_VELOCITY := 8.0

const WALK_SPEED := 5.0
const SPRINT_SPEED := 8.0
const WALL_LEAP_SPEED := 10.0
var speed

@export var wallrun_cooldown : Timer
var can_wallrun : bool = true:
	get:
		if player.is_on_wall():
			if !player.get_slide_collision(0).get_collider().is_in_group("boundaries") and wallrun_cooldown.is_stopped() and !input.is_crouch_pressed:
				return true
			return false
		return false
var is_in_wall_leap : bool = false

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
	if msg.has("do_wall_leap"):
		is_in_wall_leap = true
		
func exit():
	# Re-enable head bob
	player.can_head_bob = true
	# Reset is_in_wall_jump
	is_in_wall_leap = false

func physics_update(delta : float):
	# Apply gravity
	player.update_gravity(delta)
	
	# Set horizontal speed
	if is_in_wall_leap:
		speed= WALL_LEAP_SPEED
	elif input.is_sprint_pressed:
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
		if input.is_jump_pressed and input.is_sprint_pressed and can_wallrun:
			transition.emit("WallrunPlayerState")
