class_name Pistol

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
			var distance = Vector3(collider.global_position - camera.global_position).length()
			
			if collider.is_weak_point:
				var dmg = damage_with_falloff(crit_damage, distance)
				collider.take_damage.rpc(dmg)
				crit_hit.emit(dmg)
				print("Damage done: %s" % dmg)
			else:
				var dmg = damage_with_falloff(BULLET_DAMAGE, distance)
				collider.take_damage.rpc(dmg)
				regular_hit.emit(dmg)
				print("Damage done: %s" % dmg)
	else:
		print ("Hit nothing.")
