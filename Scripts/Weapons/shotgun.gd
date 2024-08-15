class_name Shotgun
extends Weapon

@export_category("Shotgun Data")
@export var bullet_count : int
@export var bullet_spread : int = 70

@export var shotgun_gunshots_sfx : AudioStreamPlayer3D
@export var shotgun_pump_sfx : AudioStreamPlayer3D

var player : MultiplayerPlayer
var knockback := 0.5
var aim_dir : Vector3

func shoot() -> void:
	# Call base method
	super()
	shotgun_gunshots_sfx.play()
	
	var space_state = camera.get_world_3d().direct_space_state
	var screen_centre = get_viewport().get_size() / 2
	
	var ray_origin = camera.project_ray_origin(screen_centre)
	
	for n in bullet_count:
		var ray_end := Vector3.ZERO
		
		if n == 0:
			ray_end = ray_origin + camera.project_ray_normal(screen_centre) * HITSCAN_RAY_RANGE
		else:
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var random_spread = Vector2i(random_direction * randf_range(0.0, bullet_spread))
			
			ray_end = ray_origin + camera.project_ray_normal(screen_centre + random_spread) * HITSCAN_RAY_RANGE
	
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, HITSCAN_COLLISION_MASK)
		if n == 0: aim_dir = (ray_end - ray_origin).normalized()
		query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		if result: raycast_hit(result)
		else: print("Hit nothing.")
		
func pump_sound():
	shotgun_pump_sfx.play()
		
		## Apply knockback when in air
		#var player_state : PlayerState = player.state_machine.current_state
		#if player_state.name == "AirPlayerState":
			#print("Aim direction length: " + str(aim_dir.length()))
			#var knockback_vec = -aim_dir * knockback
			#print("Knockback length: " + str(knockback_vec.length()))
			##player.velocity.x += knockback_vec.x
			##player.velocity.y += knockback_vec.y
			##player.velocity.z += knockback_vec.z
			#player.velocity += knockback_vec
