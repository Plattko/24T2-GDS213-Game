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
	
	var cur_location = enemy.global_position
	
	## TODO: Make it so shooting rockets at enemies once navigation is finished still knocks them back
	# Handle movement
	if !enemy.nav_agent.is_navigation_finished():
		if enemy.is_on_floor():
			var next_location = enemy.nav_agent.get_next_path_position()
			var new_velocity = (next_location - cur_location).normalized() * enemy.speed
			enemy.velocity = enemy.velocity.move_toward(new_velocity, 0.25) # NOTE: DO NOT CHANGE!!!
		else:
			enemy.velocity.y -= 18 * _delta
		enemy.move_and_slide()
	
	# Make enemy look where they're running
	var cur_velocity = Vector2(enemy.velocity.x, enemy.velocity.z).length()
	if cur_velocity > 0.01:
		enemy.look_at(Vector3(cur_location.x + enemy.velocity.x, cur_location.y, cur_location.z + enemy.velocity.z), Vector3.UP)

func on_link_reached(details : Dictionary) -> void:
	var height = abs(details.link_exit_position.y - details.link_entry_position.y)
	if details.link_exit_position.y >= details.link_entry_position.y:
		if height < max_jump_height:
			transition.emit("JumpEnemyState", details)
		else:
			printerr("Enemy cannot jump that far.")
	elif details.link_exit_position.y < details.link_entry_position.y:
		if height < max_drop_height:
			details["height"] = height
			transition.emit("DropEnemyState", details)
		else:
			printerr("Enemy cannot drop that far.")
