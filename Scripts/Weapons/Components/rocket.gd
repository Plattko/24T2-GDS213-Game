extends CharacterBody3D

@export var explosion_scene = load("res://Scenes/Weapons/Components/explosion.tscn")
@export var mesh : MeshInstance3D
@export var collision_shape : CollisionShape3D
var rocket_launcher : RocketLauncher

var direction : Vector3
var speed : float
var has_exploded : bool = false

@export var owner_id : int

func _enter_tree() -> void:
	if !multiplayer.is_server():
		set_physics_process(false)
		return
	mesh.visible = false

func _physics_process(delta) -> void:
	# Only run by server
	var collision : KinematicCollision3D = move_and_collide(direction * speed * delta)
	if collision and !has_exploded:
		has_exploded = true
		if !(collision.get_collider() is Enemy):
			rocket_launcher.spawn_decal(rocket_launcher.blast_decal, collision.get_position(), collision.get_normal())
		spawn_explosion(collision)

func spawn_explosion(collision: KinematicCollision3D) -> void:
	# Disable the rocket's collision
	collision_shape.disabled = true
	# Instantiate the explosion
	var explosion = explosion_scene.instantiate()
	# Give the player that shot the rocket ownership of it
	explosion.owner_id = owner_id
	# Give it a reference to the rocket launcher
	explosion.rocket_launcher = rocket_launcher
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(explosion, true)
	# Set its position
	explosion.global_position = collision.get_position()
	# Delete the rocket
	queue_free()

func _on_visibility_delay_timeout() -> void:
	if !multiplayer.is_server(): return
	mesh.visible = true
