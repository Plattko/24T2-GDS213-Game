class_name P90
extends Weapon

@export_group("P90 Data")
@export var bullet_spread : int = 25

@export var P90_gunshots_sfx : AudioStreamPlayer3D

func shoot() -> void:
	# Call base method
	super()
	P90_gunshots_sfx.play()
	
	var space_state = camera.get_world_3d().direct_space_state
	var screen_centre = get_viewport().get_size() / 2
	
	var ray_origin = camera.project_ray_origin(screen_centre)
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_spread = Vector2i(random_direction * randf_range(0.0, bullet_spread))
	var ray_end = ray_origin + camera.project_ray_normal(screen_centre + random_spread) * HITSCAN_RAY_RANGE
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, HITSCAN_COLLISION_MASK)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result: raycast_hit(result)
	else: print("Hit nothing.")
