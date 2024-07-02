class_name Rifle

extends Weapon

const RAY_RANGE := 2000.0

func shoot() -> void:
	# Call base method
	super()
	
	var space_state = camera.get_world_3d().direct_space_state
	var screen_centre = get_viewport().get_size() / 2
	
	var ray_origin = camera.project_ray_origin(screen_centre)
	var ray_end = ray_origin + camera.project_ray_normal(screen_centre) * RAY_RANGE
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, HITSCAN_COLLISION_MASK)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		print("Hit: " + result.collider.name)
		spawn_decal(result.get("position"), result.get("normal"))
		
		var collider = result.collider
		if collider is Damageable:
			if collider.is_weak_point:
				collider.take_damage(crit_damage)
				print("Damage done: %s" % crit_damage)
			else:
				collider.take_damage(BULLET_DAMAGE)
				print("Damage done: %s" % BULLET_DAMAGE)
	else:
		print ("Hit nothing.")
