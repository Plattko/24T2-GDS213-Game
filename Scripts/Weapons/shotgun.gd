class_name Shotgun

extends Weapon

const RAY_RANGE := 2000.0

@export_category("Shotgun Data")
@export var bullet_count : int
@export var bullet_spread : int

func shoot() -> void:
	# Call base method
	super()
	
	var space_state = camera.get_world_3d().direct_space_state
	var screen_centre = get_viewport().get_size() / 2
	
	var ray_origin = camera.project_ray_origin(screen_centre)
	
	for n in bullet_count:
		var ray_end := Vector3.ZERO
		
		if n == 0:
			ray_end = ray_origin + camera.project_ray_normal(screen_centre) * RAY_RANGE
		else:
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var random_spread = Vector2i(random_direction * randf_range(0.0, bullet_spread))
			
			ray_end = ray_origin + camera.project_ray_normal(screen_centre + random_spread) * RAY_RANGE
	
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		
		if result:
			print("Hit: " + result.collider.name)
			spawn_decal(result.get("position"), result.get("normal"))
			
			var collider = result.collider
			if collider is Damageable:
				collider.take_damage.rpc(BULLET_DAMAGE)
		else:
			print ("Hit nothing.")
