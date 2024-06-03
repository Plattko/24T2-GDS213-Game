class_name CrouchPlayerState

extends PlayerState

const WALK_SPEED = 5.0
const CROUCH_ANIM_SPEED : float = 7.0

var is_crouch_released : bool = false

func enter(previous_state) -> void:
	print("Entered Crouch player state.")
	# Play the crouch animation
	if previous_state.name != "SlidePlayerState":
		player.animation_player.play("Crouch", -1, CROUCH_ANIM_SPEED)
	else:
		player.animation_player.current_animation = "Crouch"
		player.animation_player.seek(1.0, true)

func exit():
	is_crouch_released = false

func physics_update(delta) -> void:
	# Handle movement
	player.velocity.x = player.direction.x * WALK_SPEED
	player.velocity.z = player.direction.z * WALK_SPEED
	player.move_and_slide()
	
	if Input.is_action_just_released("crouch") or Input.is_action_pressed("jump"):
		uncrouch()
	elif !Input.is_action_pressed("crouch") and !is_crouch_released:
		is_crouch_released = true
		uncrouch()

func uncrouch() -> void:
	# If there is nothing blocking the player from standing up, play the uncrouch animation and transition to the Idle state
	if player.crouch_shape_cast.is_colliding() == false:
		player.animation_player.play("Crouch", -1, -CROUCH_ANIM_SPEED, true)
		if player.animation_player.is_playing():
			await player.animation_player.animation_finished
		transition.emit("IdlePlayerState")
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif player.crouch_shape_cast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch()
