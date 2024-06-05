extends Node3D

@export var anim_player : AnimationPlayer

var raycast_test = preload("res://Scenes/raycast_test.tscn")
var bullet_decal = preload("res://Scenes/bullet_decal.tscn")

const RAY_RANGE := 2000.0

const BULLET_DAMAGE := 10.0

const MAX_AMMO := 24
var cur_ammo

var decal_queue = []
const MAX_QUEUE_SIZE := 30

func _ready():
	cur_ammo = MAX_AMMO

func _physics_process(delta):
	# Handle shooting
	if Input.is_action_pressed("shoot"):
		if !anim_player.is_playing():
			if cur_ammo > 0:
				shoot()
			else:
				reload()
	
	if Input.is_action_pressed("reload"):
		if !anim_player.is_playing() and cur_ammo < MAX_AMMO:
			reload()

func shoot() -> void:
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
		spawn_decal(result.get("position"), result.get("normal"))
		
		var collider = result.collider
		if collider is Damageable:
			collider.take_damage(BULLET_DAMAGE)
	else:
		print ("Hit nothing.")
	
	cur_ammo -= 1

func reload() -> void:
	anim_player.play("Reload")
	await anim_player.animation_finished
	cur_ammo = MAX_AMMO

func test_raycast(position: Vector3) -> void:
	var instance = raycast_test.instantiate()
	get_tree().root.add_child(instance)
	instance.global_position = position
	await get_tree().create_timer(3.0).timeout
	instance.queue_free()

func spawn_decal(position: Vector3, normal: Vector3) -> void:
	# Instantiate bullet decal
	var instance = bullet_decal.instantiate()
	# Make it a child of the scene
	get_tree().root.add_child(instance)
	# Set its position
	instance.global_position = position
	
	instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
	
	if normal != Vector3.UP and normal != Vector3.DOWN:
		instance.rotate_object_local(Vector3(1, 0, 0), 90)
	
	update_decal_queue(instance)
	
	## Destroy the decal after 3 seconds
	#await get_tree().create_timer(3.0).timeout
	#instance.queue_free()

func update_decal_queue(decal):
	decal_queue.push_back(decal)
	
	if decal_queue.size() > MAX_QUEUE_SIZE:
		var decal_to_destroy = decal_queue.pop_front()
		decal_to_destroy.queue_free()
