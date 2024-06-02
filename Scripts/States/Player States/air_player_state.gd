class_name AirPlayerState

extends PlayerState

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
var speed

func enter():
	print("Entered Air player state.")

func physics_update(delta : float):
	# Apply gravity
	player.update_gravity(delta)
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Handle movement
	player.velocity.x = lerp(player.velocity.x, player.direction.x * speed, delta * 4.0)
	player.velocity.z = lerp(player.velocity.z, player.direction.z * speed, delta * 4.0)
	
	player.move_and_slide()
	
	if player.is_on_floor():
		if !player.direction:
			transition.emit("IdlePlayerState")
		elif player.direction and Input.is_action_pressed("sprint"):
			transition.emit("SprintPlayerState")
		elif player.direction and !Input.is_action_pressed("sprint"):
			transition.emit("WalkPlayerState")
		return
