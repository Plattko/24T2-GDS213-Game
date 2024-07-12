extends Node3D

@export var explosion_col : CollisionShape3D

var knockback_strength : float = 12.0

func _ready():
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _physics_process(delta) -> void:
	if !explosion_col.disabled:
		explosion_col.disabled = true
		set_physics_process(false)

func _on_explosion_radius_body_entered(body):
	if body is MultiplayerPlayer:
		print("Player detected in explosion.")
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
		# Calculate the knockback
		var knockback : Vector3 = direction * knockback_strength * magnitude
		print("Knockback: " + str(knockback))
		print("Knockback strength: " + str(knockback.length()))
		
		# Apply the explosion knockback to the player
		body.velocity += knockback
