class_name Shotgun

extends Weapon

const RAY_RANGE := 2000.0

@export_category("Shotgun Data")
@export var bullet_count : int
@export var bullet_spread : int

var player : MultiplayerPlayer
var knockback := 0.5
var aim_dir : Vector3

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
	
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, HITSCAN_COLLISION_MASK)
		if n == 0: aim_dir = (ray_end - ray_origin).normalized()
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
					collider.take_damage.rpc(dmg,true)
					crit_hit.emit(dmg)
					print("Damage done: %s" % dmg)
				else:
					var dmg = damage_with_falloff(BULLET_DAMAGE, distance)
					collider.take_damage.rpc(dmg, false)
					regular_hit.emit(dmg)
					print("Damage done: %s" % dmg)
		else:
			print ("Hit nothing.")
		
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
