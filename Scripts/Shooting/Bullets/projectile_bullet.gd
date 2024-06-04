extends Node3D

const SPEED := 40.0

@export var mesh : MeshInstance3D
@export var ray_cast : RayCast3D
@export var collision_particles : GPUParticles3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	# Move bullet
	translate(Vector3(0.0, 0.0, -SPEED) * delta) # CAN CAUSE BULLET NOT TO COLLIDE WITH OBJECT
	
	# Handle collision
	if ray_cast.is_colliding():
		# Hide bullet
		mesh.visible = false
		# Emit collision particles
		collision_particles.emitting = true
		# Delete bullet after particle finishes
		await get_tree().create_timer(collision_particles.lifetime).timeout
		queue_free()

func _on_bullet_timer_timeout():
	queue_free()
