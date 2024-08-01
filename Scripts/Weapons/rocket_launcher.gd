class_name RocketLauncher

extends Weapon

var rocket_scene = load("res://Scenes/Weapons/Components/rocket.tscn")
@export var rocket_speed : float = 29.0

func shoot() -> void:
	# Call base method
	super()
	
	# Instantiate the rocket
	var rocket = rocket_scene.instantiate() as CharacterBody3D
	# Give it a reference to the rocket launcher
	rocket.rocket_launcher = self
	# Set its direction and speed
	rocket.direction = -camera.get_global_transform().basis.z
	rocket.speed = rocket_speed
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(rocket)
	# Set its position
	rocket.global_position = camera.global_position
	# Set its rotation
	rocket.transform.basis = camera.global_transform.basis

func on_enemy_hit(damage: float) -> void:
	regular_hit.emit(damage)
