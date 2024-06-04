extends Node3D

@export var anim_player : AnimationPlayer

var raycast_test = preload("res://Scenes/raycast_test.tscn")

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
		
		if result:
			print("Hit: " + result.collider.name)
			test_raycast(result.get("position"))
		else:
			print ("Hit nothing.")

func test_raycast(position: Vector3) -> void:
	var instance = raycast_test.instantiate()
	get_tree().root.add_child(instance)
	instance.global_position = position
	await get_tree().create_timer(3.0).timeout
	instance.queue_free()
