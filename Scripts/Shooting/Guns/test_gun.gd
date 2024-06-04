extends Node3D

@export var anim_player : AnimationPlayer
var camera : Camera3D

const RAY_RANGE := 2000.0

func _ready():
	await get_parent().is_node_ready()
	camera = get_parent() as Camera3D
	assert (camera is Camera3D)

func _physics_process(delta):
	# Handle shooting
	if Input.is_action_pressed("shoot"):
		shoot()

func shoot():
	if !anim_player.is_playing():
		anim_player.play("Shoot")
		
		var screen_centre = get_viewport().get_size() / 2
		
		var ray_origin = camera.project_ray_origin(screen_centre)
		var ray_end = ray_origin + camera.project_ray_normal(screen_centre) * RAY_RANGE
		
		var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		new_intersection.collide_with_areas = true
		
		var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
		
		if !intersection.is_empty():
			print("Hit: " + intersection.collider.name)
		else:
			print ("Hit nothing.")
