class_name DownedPlayerState
extends PlayerState

const DOWNED_ANIM_SPEED : float = 7.0

func enter(msg : Dictionary = {}) -> void:
	print("Entered Downed State.")
	if msg.has("left_crouch") or msg.has("left_slide"):
		# Transition to downed animation from crouch or slide animation
		player.seek_anim.rpc(player.DOWNED_ANIM, 1.0)
	else:
		# Play the downed animation
		player.play_anim.rpc(player.DOWNED_ANIM, DOWNED_ANIM_SPEED)

func physics_update(delta) -> void:
	# Apply gravity
	if !player.is_on_floor():
		player.update_gravity(delta)
	
	# Handle movement
	var velocity : Vector3 = set_velocity(input.direction, DOWNED_SPEED)
	player.update_velocity(velocity)

#@rpc("any_peer", "call_local")
func revive_player() -> void:
	if !player.ceiling_check.is_colliding() and !input.is_crouch_pressed:
		player.play_anim.rpc(player.DOWNED_ANIM, -DOWNED_ANIM_SPEED, true)
		transition.emit("IdlePlayerState")
	else:
		transition.emit("CrouchPlayerState", {"left_downed" = true})
