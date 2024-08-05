class_name RocketLauncher
extends Weapon

var rocket_scene = load("res://Scenes/Weapons/Components/rocket.tscn")
@export var rocket_speed : float = 29.0

func shoot() -> void:
	# Call base method
	super()
	
	var player_id = get_multiplayer_authority()
	var dir = -camera.get_global_transform().basis.z
	var pos = camera.global_position
	var rot = camera.global_transform.basis
	spawn_rocket.rpc_id(1, player_id, dir, rocket_speed, pos, rot)

@rpc("any_peer", "call_local")
func spawn_rocket(player_id: int, dir: Vector3, speed: float, pos: Vector3, rot: Basis) -> void:
	# Instantiate the rocket
	var rocket = rocket_scene.instantiate() as CharacterBody3D
	# Give the player that shot the rocket ownership of it
	rocket.owner_id = player_id
	# Give it a reference to the rocket launcher
	rocket.rocket_launcher = self
	# Set its direction and speed
	rocket.direction = dir
	rocket.speed = speed
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(rocket, true)
	# Set its position and rotation
	rocket.global_position = pos
	rocket.transform.basis = rot

func on_enemy_hit(damage: float) -> void:
	regular_hit.emit(damage)
