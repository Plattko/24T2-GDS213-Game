class_name AirPlayerState

extends PlayerState

const JUMP_VELOCITY := 8.0

var speed

# Wallrun variables
@export_group("Wallrun Variables")
@export var floor_check : RayCast3D
@export var wallrun_cooldown : Timer
#const WALL_RUN_MIN_SPEED := 5.1
const WALL_LEAP_SPEED := 10.0
var is_player_facing_wall : bool = false:
	get:
		# Get player look direction
		var look_dir = Vector2(-player.transform.basis.z.x, -player.transform.basis.z.z).normalized()
		# Get the direction of the wall
		var normal_vector = player.get_slide_collision(0).get_normal()
		var wall_dir = -Vector2(normal_vector.x, normal_vector.z)
		# Return true if player is facing within 30 degrees of the wall's direction
		if wall_dir.dot(look_dir) > 0.866: return true
		return false
var can_wallrun : bool = true:
	get:
		# Is the player on a wall?
		if player.is_on_wall():
			# Is wall a map boundary?
			if player.get_slide_collision(0).get_collider().is_in_group("boundaries"): return false
			# Is wall run on cooldown?
			elif !wallrun_cooldown.is_stopped(): return false
			# Is the player mantling?
			elif !mantle_duration.is_stopped(): return false
			# Is player facing the wall?
			elif is_player_facing_wall: return false
			# Is the player too close to the floor?
			elif floor_check.is_colliding(): return false
			# If none of the above and on a wall, return true
			else: return true
		return false
var is_in_wall_leap : bool = false

# Mantle variables
@export_group("Mantle Variables")
@export var ledge_check : RayCast3D
@export var wall_check : ShapeCast3D
@export var mantle_duration : Timer
var can_climb : bool = false:
	get:
		if wall_check.is_colliding() and !ledge_check.is_colliding():
			return true
		return false

# Air Strafing variables
@export_group("Air Strafing Variables")
@export var is_air_strafing_enabled : bool = true
@export var max_air_speed : float = 0.8
const MAX_ACCEL : float = 8.5 * 10.0

func enter(msg : Dictionary = {}):
	#print("Entered Air player state.")
	
	## TODO: When working on other knockback change this to a check for if the player is rocket jumping
	if abs(player.horizontal_knockback.length()) > 0.0:
		is_air_strafing_enabled = true
	
	# Disable head bob
	player.can_bob = false
	
	if msg.has("do_jump"):
		player.velocity.y += JUMP_VELOCITY
	if msg.has("left_wallrun"):
		wallrun_cooldown.start()
	if msg.has("do_wall_leap"):
		is_in_wall_leap = true
		speed = WALL_LEAP_SPEED

func exit():
	# Re-enable head bob
	player.can_bob = true
	# Reset is_in_wall_jump
	is_in_wall_leap = false
	# Reset mantle duration timer
	mantle_duration.stop()
	# Reset air strafing
	if is_air_strafing_enabled: is_air_strafing_enabled = false

func physics_update(delta : float):
	# Transition to Downed state
	if player.is_downed:
		transition.emit("DownedPlayerState")
		return
	
	# Apply gravity
	player.update_gravity(delta)
	
	# Set horizontal speed
	if !is_in_wall_leap:
		if input.is_sprint_pressed:
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
	
	# Handle mantling
	if can_climb and input.is_move_forwards_pressed:
		mantle()
	
	# Handle movement
	if is_air_strafing_enabled:
		player.velocity = update_air_vel(delta)
		player.move_and_slide()
	else:
		## V1
		#player.velocity.x = lerp(player.velocity.x, input.direction.x * speed, delta * 4.0)
		#player.velocity.z = lerp(player.velocity.z, input.direction.z * speed, delta * 4.0)
		
		## V2
		#if input.direction.x != 0:
			#player.velocity.x = lerp(player.velocity.x, input.direction.x * speed, delta * 4.0)
		#if input.direction.z != 0:
			#player.velocity.z = lerp(player.velocity.z, input.direction.z * speed, delta * 4.0)
		#player.move_and_slide()
		
		## Last version
		#var velocity : Vector3 = player.velocity
		#if input.direction.x != 0:
			#velocity.x = lerp(velocity.x, input.direction.x * speed, delta * 4.0)
		#if input.direction.z != 0:
			#velocity.z = lerp(velocity.z, input.direction.z * speed, delta * 4.0)
		#player.update_velocity(velocity)
		##player.update_velocity(Vector3.ZERO)
		
		## Handle player movement
		var player_vel : Vector3 = player.velocity
		#print("Player vel: " + str(Vector2(player_vel.x, player_vel.z)))
		var lerped_vel : Vector3 = player_vel
		
		if input.direction.x != 0:
			lerped_vel.x = lerp(player_vel.x, input.direction.x * speed, delta * 4.0)
		if input.direction.z != 0:
			lerped_vel.z = lerp(player_vel.z, input.direction.z * speed, delta * 4.0)
		#print("Lerped vel: " + str(Vector2(lerped_vel.x, lerped_vel.z)))
		
		#var target_vel : Vector3 = (lerped_vel - player_vel)
		#print("Target vel: " + str(Vector2(target_vel.x, target_vel.z)))
		
		if player.horizontal_knockback == Vector3.ZERO:
			player.update_velocity(lerped_vel)
	
	# Handle landing
	if player.is_on_floor():
		# Transition to Crouch state if roof is too low
		if player.ceiling_check.is_colliding() == true:
			transition.emit("CrouchPlayerState")
		# Handle crouch
		elif input.is_crouch_pressed:
			# Transition to Slide state
			if input.is_move_forwards_pressed and input.is_sprint_pressed and horizontal_velocity.length() > 6.0:
				transition.emit("SlidePlayerState")
			# Transition to Crouch state
			else:
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
		if input.is_jump_pressed and input.is_sprint_pressed and !input.is_crouch_pressed and can_wallrun:
			transition.emit("WallrunPlayerState")

func mantle() -> void:
		mantle_duration.start()
		is_air_strafing_enabled = false
		player.velocity.y = 8.0

func update_air_vel(delta: float) -> Vector3:
	var cur_speed = horizontal_velocity.dot(Vector2(input.direction.x, input.direction.z))
	var speed_to_add = clamp(max_air_speed - cur_speed, 0.0, MAX_ACCEL * delta)
	
	return player.velocity + speed_to_add * input.direction
