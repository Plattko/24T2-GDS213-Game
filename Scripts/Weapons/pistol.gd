class_name Pistol
extends Weapon

func shoot() -> void:
	# Call base method
	super()
	
	var space_state = camera.get_world_3d().direct_space_state
	var screen_centre = get_viewport().get_size() / 2
	
	var ray_origin = camera.project_ray_origin(screen_centre)
	var ray_end = ray_origin + camera.project_ray_normal(screen_centre) * HITSCAN_RAY_RANGE
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, HITSCAN_COLLISION_MASK)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result: raycast_hit(result)
	else: print("Hit nothing.")
