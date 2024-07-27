class_name RunEnemyState
extends EnemyState

func enter(_msg : Dictionary = {}):
	if multiplayer.is_server():
		enemy.animate(enemy.Animations.RUN)
	else:
		enemy.animate(enemy.cur_anim)

func physics_update(_delta : float) -> void:
	# Transition to Attack state if player is in range
	if enemy.target_in_range():
		transition.emit("AttackEnemyState")
		return
	
	if enemy.is_on_floor():
		# Update movement
		var cur_location : Vector3 = enemy.global_position
		var next_location : Vector3 = enemy.nav_agent.get_next_path_position()
		var new_velocity : Vector3 = (next_location - cur_location).normalized() * enemy.speed
		enemy.nav_agent.set_velocity(new_velocity)
	# Apply gravity when in the air
	else:
		enemy.velocity.y -= 18 * _delta
	
	# Make enemy look where they're running
	var cur_velocity = Vector2(enemy.velocity.x, enemy.velocity.z).length()
	if cur_velocity > 0.01:
		enemy.look_at(Vector3(enemy.global_position.x + enemy.velocity.x, enemy.global_position.y, enemy.global_position.z + enemy.velocity.z), Vector3.UP)

func on_link_reached(details : Dictionary) -> void:
	var height = abs(details.link_exit_position.y - details.link_entry_position.y)
	if details.link_exit_position.y >= details.link_entry_position.y:
		if height < max_jump_height:
			transition.emit("JumpEnemyState", details)
	elif details.link_exit_position.y < details.link_entry_position.y:
		if height < max_drop_height:
			details["height"] = height
			transition.emit("DropEnemyState", details)
