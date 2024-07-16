extends Node3D

@export var explosion_col : CollisionShape3D

@export var explosion_damage : float = 56.0
var self_damage : float = explosion_damage * 0.6
var knockback_strength : float = 12.0

func _ready():
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _physics_process(_delta) -> void:
	if !explosion_col.disabled:
		explosion_col.disabled = true
		set_physics_process(false)

## TODO: Make it so only the player who shot the rocket is effected
## TODO: Add damaging enemies
## TODO: Add self-damage
func _on_explosion_radius_body_entered(body):
	if body is MultiplayerPlayer:
		# Raycast from the explosion's centre to the player's eyes
		var query = PhysicsRayQueryParameters3D.create(global_position, body.head.global_position)
		
		# Find where the raycast intersected with the player's hitbox
		var space_state = body.camera.get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		var hitbox_position : Vector3 = result.position
		
		# Calculate direction and distance from the explosion's centre to the hitbox position
		var target_vector : Vector3 = Vector3(hitbox_position - global_position)
		var direction : Vector3 = target_vector.normalized()
		var distance : float = target_vector.length()
		
		# Calculate the knockback's magnitude
		var magnitude : float = lerpf(1.0, 0.5, distance / explosion_col.shape.radius)
		# Calculate the self-damage
		var damage : float = self_damage * magnitude
		# Calculate the knockback
		var knockback : Vector3 = direction * knockback_strength * magnitude
		#print("Knockback: " + str(knockback))
		#print("Knockback strength: " + str(knockback.length()))
		
		# Apply the self-damage
		body.on_damaged(damage)
		# Apply the vertical explosion knockback to the player
		body.velocity.y += knockback.y
		# Apply the horizontal explosion knockback to the player
		var player_state : PlayerState = body.state_machine.current_state
		if player_state.name == "AirPlayerState":
			# If in the Air state, add it to the velocity directly
			player_state.is_air_strafing_enabled = true
			body.velocity.x += knockback.x * 1.3
			body.velocity.z += knockback.z * 1.3
		else:
			# Otherwise, update the horizontal knockback
			body.horizontal_knockback = knockback * 1.3
