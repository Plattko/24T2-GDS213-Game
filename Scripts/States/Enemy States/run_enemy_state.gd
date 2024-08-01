class_name RunEnemyState
extends EnemyState

@export_group("Soft Collision Variables")
@export var soft_collision : Area3D
@export var push_force : float = 20.0

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
			enemy.velocity = enemy.velocity.move_toward(new_velocity, enemy.turn_speed) # NOTE: DO NOT CHANGE!!!
		else:
			enemy.velocity.y -= 18 * delta
		## Apply soft collision push
		### TODO: Make it so soft collision prevents enemies bunching up after reaching destination
		#var push = soft_collide() * delta * push_force
		#enemy.velocity += push
		collision()
	
	# Make enemy look where they're running
	var cur_velocity = Vector3(enemy.velocity.x, 0.0, enemy.velocity.z)
	if cur_velocity.length() > 0.01:
		rotate_towards(cur_velocity, delta)

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

func soft_collide() -> Vector3:
	var overlapping_areas = soft_collision.get_overlapping_areas()
	
	if overlapping_areas:
		var area = overlapping_areas[0]
		var push_dir = area.global_position.direction_to(enemy.global_position)
		push_dir.y = 0.0
		return push_dir
	return Vector3.ZERO

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

#func soft_collide() -> Vector3:
	#var area_count = 0
	#var push_sum = Vector3.ZERO
	#var overlapping_areas = soft_collision.get_overlapping_areas()
	#
	#if overlapping_areas:
		## Add each push vector to the push sum
		#for area in overlapping_areas:
			## Get the push direction
			#var push_dir = area.global_position.direction_to(enemy.global_position)
			## Get the other area's distance from the enemy
			#var dist = Vector3(enemy.global_position - area.global_position).length()
			## Set the push vector to the direction divided by the distance
			#var push_vec = push_dir / dist
			## Add it to the push sum
			#push_sum += push_vec
			## Increase the area count
			#area_count += 1
		#
		## Get the mean push direction by dividing it by the area count
		#push_sum = (push_sum / area_count).normalized()
		## Multiply it by the push force
		#push_sum = push_sum * push_force
		## Zero the y velocity
		#push_sum.y = 0.0
		## Return the average push of all nearby enemies
		#return push_sum
		#
		##var area = overlapping_areas[0]
		##var push_dir = area.global_position.direction_to(enemy.global_position)
		##push_dir.y = 0.0
		##return push_dir
	#return Vector3.ZERO

func collision() -> void:
	enemy.move_and_slide()
