extends CharacterBody3D

@export var explosion_scene = preload("res://Scenes/Weapons/Components/explosion.tscn")
@export var collision_shape : CollisionShape3D

var direction : Vector3
var speed : float
var has_exploded : bool = false

func _physics_process(delta) -> void:
	var collision : KinematicCollision3D = move_and_collide(direction * speed * delta)
	if collision and !has_exploded:
		has_exploded = true
		explode(collision)

func explode(collision: KinematicCollision3D) -> void:
	# Disable the rocket's collision
	collision_shape.disabled = true
	# Instantiate the explosion
	var explosion = explosion_scene.instantiate()
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(explosion)
	# Set its position
	explosion.global_position = collision.get_position()
	# Delete the rocket
	queue_free()
