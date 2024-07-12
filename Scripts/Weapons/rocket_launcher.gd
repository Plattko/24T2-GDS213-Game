class_name RocketLauncher

extends Weapon

@export var explosion_scene = preload("res://Scenes/Weapons/Components/explosion.tscn")

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
		
		# Instantiate the explosion
		var explosion = explosion_scene.instantiate()
		# Make it a child of the level scene
		var level = get_tree().get_first_node_in_group("level")
		level.add_child(explosion)
		# Set its position
		explosion.global_position = result.position
	else:
		print ("Hit nothing.")
