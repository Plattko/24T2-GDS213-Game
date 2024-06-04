extends Node3D

@export var anim_player : AnimationPlayer

const RAY_RANGE := 2000.0

func _physics_process(delta):
	# Handle shooting
	if Input.is_action_pressed("shoot"):
		shoot()

func shoot() -> void:
	if !anim_player.is_playing():
		anim_player.play("Shoot")
		
		var camera = Global.camera
		var space_state = camera.get_world_3d().direct_space_state
		var screen_centre = get_viewport().get_size() / 2
		
		var ray_origin = camera.project_ray_origin(screen_centre)
		var ray_end = ray_origin + camera.project_ray_normal(screen_centre) * RAY_RANGE
		
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		
		if !result.is_empty():
			print("Hit: " + result.collider.name)
		else:
			print ("Hit nothing.")
