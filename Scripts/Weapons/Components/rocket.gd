extends CharacterBody3D

@export var explosion_scene = load("res://Scenes/Weapons/Components/explosion.tscn")
@export var mesh : MeshInstance3D
@export var collision_shape : CollisionShape3D
var rocket_launcher : RocketLauncher

var direction : Vector3
var speed : float
var has_exploded : bool = false

func _enter_tree() -> void:
	mesh.visible = false

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
	# Give it a reference to the rocket launcher
	explosion.rocket_launcher = rocket_launcher
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(explosion)
	# Set its position
	explosion.global_position = collision.get_position()
	# Delete the rocket
	queue_free()

func _on_visibility_delay_timeout() -> void:
	mesh.visible = true
