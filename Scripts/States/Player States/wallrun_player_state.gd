class_name WallrunPlayerState
extends PlayerState

const WALLRUN_SPEED := 10.0

var wall_normal : Vector2
var last_dir := Vector2.ZERO
var velocity_dir : Vector2
var direction : Vector2

var look_dir : Vector2

var min_wall_jump := 5.0
var max_wall_jump := 8.0

const MAX_CAM_ANGLE : float = deg_to_rad(12)

# Getting stuck in corner prevention
var min_move_delta : float = 0.1
var last_pos : Vector3

func enter(_msg : Dictionary = {}):
	player.velocity.y = 0.0

func exit() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(player.camera, "rotation", Vector3.ZERO, 0.1)
	#player.camera.rotation.z = 0

func physics_update(delta: float) -> void:
	# Transition to Downed state
	if player.is_downed:
		transition.emit("DownedPlayerState")
		return
	
	if player.is_on_wall():
		# Get player velocity direction
		velocity_dir = horizontal_velocity.normalized()
		# Get player look direction
		look_dir = Vector2(-player.transform.basis.z.x, -player.transform.basis.z.z).normalized()
		# Default no velocity direction to equal the player's look direction
		if abs(velocity_dir) == Vector2.ZERO:
			velocity_dir = look_dir
		if velocity_dir != last_dir:
			# Update last direction
			last_dir = velocity_dir
			# Prevent getting stuck in a corner
			if abs(Vector3(last_pos - player.global_position).length()) < min_move_delta:
				transition.emit("AirPlayerState", {"left_wallrun" = true})
			else:
				last_pos = player.global_position
			# Get the normal of the wall
			var normal_vector = player.get_slide_collision(0).get_normal()
			wall_normal = Vector2(normal_vector.x, normal_vector.z)
			# Get both directions parallel to the wall
			var direction_1 = wall_normal.rotated(deg_to_rad(-90))
			var direction_2 = wall_normal.rotated(deg_to_rad(90))
			# Choose the direction with an angle from the player's velocity direction that is less than or equal to 90 degrees (favouring direction 1)
			#print(velocity_dir.dot(direction_1))
			if velocity_dir.dot(direction_1) >= 0:
				direction = direction_1
			else:
				direction = direction_2
		
		# Tilt the player's camera based on the angle between their look direction and wall's normal
		var look_angle = wall_normal.angle_to(look_dir)
		var look_sin = sin(look_angle) * MAX_CAM_ANGLE
		player.camera.rotation.z = lerp_angle(player.camera.rotation.z, look_sin, delta * 12.0)
		#print("Camera rotation: " + str(rad_to_deg(player.camera.rotation.z)))
		
		## Last version
		# Handle movement
		#player.velocity.x = direction.x * WALLRUN_SPEED
		#player.velocity.z = direction.y * WALLRUN_SPEED
		#player.move_and_slide()
		
		# Handle movement
		var velocity : Vector3 = set_velocity(Vector3(direction.x, 0.0, direction.y), WALLRUN_SPEED)
		player.update_velocity(velocity)
	
	# Handle landing
	if player.is_on_floor():
		# Transition to Idle state
		if !input.direction:
			transition.emit("IdlePlayerState")
		# Transition to Sprint state
		elif input.direction and input.is_sprint_pressed:
			transition.emit("SprintPlayerState")
		# Transition to Walk state
		elif input.direction and !input.is_sprint_pressed:
			transition.emit("WalkPlayerState")
	else:
		# Transition to Air state
		if !player.is_on_wall() or input.is_crouch_pressed:
			transition.emit("AirPlayerState", {"left_wallrun" = true})
		if input.is_jump_just_released:
			wall_jump()
			transition.emit("AirPlayerState", {"left_wallrun" = true, "do_wall_leap" = true})

func wall_jump() -> void:
	var cam_angle = rad_to_deg(player.head.rotation.x)
	var cam_angle_normalised = clampf(cam_angle, 0, 45) / 45
	#print("Cam angle: " + str(cam_angle))
	#print("Cam angle normalised: " + str(cam_angle_normalised))
	
	player.velocity.y = lerpf(min_wall_jump, max_wall_jump, cam_angle_normalised)
	#print("Wall jump velocity: " + str(player.velocity.y))
