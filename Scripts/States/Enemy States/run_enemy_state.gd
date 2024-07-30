class_name RunEnemyState
extends EnemyState

@export_group("Soft Collision Variables")
@export var soft_collision : Area3D
@export var push_force : float = 6.0

#@export var desired_separation : float = 1.25
#@export var max_separation_speed : float = 5.0
#@export var max_separation_force : float = 2.5

func enter(_msg : Dictionary = {}):
	if multiplayer.is_server():
		enemy.animate(enemy.Animations.RUN)
	else:
		enemy.animate(enemy.cur_anim)

func physics_update(delta : float) -> void:
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
			enemy.velocity.y -= 18 * delta
		# Apply soft collision push
		## TODO: Make it so soft collision prevents enemies bunching up after reaching destination
		var push = soft_collide() * delta * push_force
		enemy.velocity += push
		enemy.move_and_slide()
	
	# Make enemy look where they're running
	var cur_velocity = Vector2(enemy.velocity.x, enemy.velocity.z).length()
	if cur_velocity > 0.01:
		enemy.look_at(Vector3(cur_location.x + enemy.velocity.x, cur_location.y, cur_location.z + enemy.velocity.z), Vector3.UP)

func on_link_reached(details: Dictionary) -> void:
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

#func separate() -> Vector3:
	#var vec_count = 0
	#var vec_sum = Vector3.ZERO
	#
	#for body in separation_area.get_overlapping_bodies():
		#var dist = (body.global_position - enemy.global_position).length()
		#if dist > 0.0 and dist < desired_separation:
			#var push = (enemy.global_position - body.global_position).normalized()
			#push = push / dist
			#vec_sum += push
			#vec_count += 1
	#
	#if vec_count > 0:
		#vec_sum = vec_sum / vec_count
		#vec_sum = vec_sum.normalized() * max_separation_speed
		##var steer = vec_sum - vel
		#var steer = vec_sum
		#steer.limit_length(max_separation_force)
		#return Vector3(steer.x, 0.0, steer.z)
	#return Vector3.ZERO

func soft_collide() -> Vector3:
	var overlapping_areas = soft_collision.get_overlapping_areas()
	
	if overlapping_areas:
		var area = overlapping_areas[0]
		var push_dir = area.global_position.direction_to(enemy.global_position)
		push_dir.y = 0.0
		return push_dir
	return Vector3.ZERO
