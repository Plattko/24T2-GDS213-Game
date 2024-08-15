extends Node3D

@export var explosion_col : CollisionShape3D
var rocket_launcher : RocketLauncher

@export var explosion_damage : float = 75.0
var self_damage : float = explosion_damage * 0.25
var knockback_strength : float = 12.0
var is_direct_hit : bool = false

@export var owner_id : int

@export var explosion_sfx : AudioStreamPlayer3D

#var do_self_damage : bool = true

const ENEMY_COLLISION_MASK : int = roundi(pow(2, 1-1)) + roundi(pow(2, 3-1))
const PLAYER_COLLISION_MASK : int = roundi(pow(2, 1-1)) + roundi(pow(2, 2-1))

func _enter_tree() -> void:
	if !multiplayer.is_server():
		set_physics_process(false)
		return
	
	await get_tree().create_timer(0.9).timeout
	await get_tree().physics_frame
	queue_free()

func _ready() -> void:
	explosion_sfx.play()

func _physics_process(_delta) -> void:
	# Only run by server
	if !explosion_col.disabled:
		explosion_col.disabled = true
		set_physics_process(false)

func _on_explosion_radius_body_entered(body: Node3D):
	# Only run by server
	if !multiplayer.is_server(): return
	
	if body is Enemy:
		print("Enemy detected")
		# Raycast from the explosion's centre to the enemy's collider
		var query = PhysicsRayQueryParameters3D.create(global_position, body.collider.global_position, ENEMY_COLLISION_MASK)
		query.hit_from_inside = true
		
		# Find where the raycast intersected with the enemy's hitbox
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		is_direct_hit = true if result.normal == Vector3.ZERO else false
		
		# Calculate direction and distance from the explosion's centre to the hitbox/collider position
		var target_vector : Vector3
		if is_direct_hit:
			target_vector = Vector3(body.collider.global_position - global_position)
		else:
			var hitbox_position : Vector3 = result.position
			target_vector = Vector3(hitbox_position - global_position)
		var direction : Vector3 = target_vector.normalized()
		var distance : float = target_vector.length()
		
		# Calculate the magnitude
		var magnitude : float
		if is_direct_hit:
			magnitude = 1.0
		else:
			magnitude = lerpf(1.0, 0.5, distance / explosion_col.shape.radius)
		# Calculate the damage
		var damage : float = explosion_damage * magnitude
		# Calculate the knockback
		var knockback : Vector3 = direction * knockback_strength * magnitude
		
		# Apply the damage
		body.on_damaged.rpc(damage, false)
		# Notify the rocket launcher an enemy was hit
		rocket_launcher.on_enemy_hit.rpc_id(owner_id, damage)
		# Apply the explosion knockback
		body.velocity += knockback
	
	elif body is MultiplayerPlayer:
		#if !body.is_multiplayer_authority(): return
		if body.get_multiplayer_authority() != owner_id:
			return
		
		# Raycast from the explosion's centre to the player's eyes
		var query = PhysicsRayQueryParameters3D.create(global_position, body.head.global_position, PLAYER_COLLISION_MASK)
		
		# Find where the raycast intersected with the player's hitbox
		var space_state = body.camera.get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		var hitbox_position : Vector3 = result.position
		
		# Calculate direction and distance from the explosion's centre to the hitbox position
		var target_vector : Vector3 = Vector3(hitbox_position - global_position)
		var direction : Vector3 = target_vector.normalized()
		var distance : float = target_vector.length()
		
		# Calculate the magnitude
		var magnitude : float = lerpf(1.0, 0.5, distance / explosion_col.shape.radius)
		# Calculate the self-damage
		var damage : float = self_damage * magnitude
		# Calculate the knockback
		var knockback : Vector3 = direction * knockback_strength * magnitude
		#print("Knockback: " + str(knockback))
		#print("Knockback strength: " + str(knockback.length()))
		
		# NOTE: Super jank setup, only workaround I could find
		body.rocket_self_hit.rpc_id(owner_id, damage, knockback)
		
		## Apply the self-damage
		#if body.do_self_damage: body.on_damaged(damage, false)
		## Apply the vertical explosion knockback to the player
		#body.velocity.y += knockback.y
		## Apply the horizontal explosion knockback to the player
		#var player_state : PlayerState = body.state_machine.current_state
		#if player_state.name == "AirPlayerState":
			## If in the Air state, add it to the velocity directly
			#player_state.is_air_strafing_enabled = true
			#body.velocity.x += knockback.x * 1.3
			#body.velocity.z += knockback.z * 1.3
		#else:
			## Otherwise, update the horizontal knockback
			#body.horizontal_knockback = knockback * 1.3
