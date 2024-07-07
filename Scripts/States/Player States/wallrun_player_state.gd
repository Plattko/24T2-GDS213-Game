class_name WallrunPlayerState
extends PlayerState

const WALLRUN_SPEED := 10.0

var wall_normal : Vector2
var last_dir := Vector2.ZERO
var velocity_dir : Vector2
var direction : Vector2

func enter(_previous_state, _msg : Dictionary = {}):
	player.velocity.y = 0.0

func physics_update(_delta: float) -> void:
	if player.is_on_wall():
		# Get player velocity direction
		velocity_dir = Vector2(player.velocity.x, player.velocity.z).normalized()
		if velocity_dir != last_dir:
			# Update last direction
			last_dir = velocity_dir
			# Get the normal of the wall
			var normal_vector = player.get_slide_collision(0).get_normal()
			wall_normal = Vector2(normal_vector.x, normal_vector.z)
			# Get both directions parallel to the wall
			var direction_1 = wall_normal.rotated(deg_to_rad(-90))
			var direction_2 = wall_normal.rotated(deg_to_rad(90))
			# Choose the direction with an angle from the player's velocity direction that is less than or equal to 90 degrees (favouring direction 1)
			print(velocity_dir.dot(direction_1))
			if velocity_dir.dot(direction_1) >= 0:
				direction = direction_1
			else:
				direction = direction_2
		
		# Handle movement
		player.velocity.x = direction.x * WALLRUN_SPEED
		player.velocity.z = direction.y * WALLRUN_SPEED
		player.move_and_slide()
	
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
		if !player.is_on_wall():
			transition.emit("AirPlayerState")
		if input.is_jump_just_released:
			transition.emit("AirPlayerState")
