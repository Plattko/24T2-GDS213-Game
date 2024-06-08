extends Node3D


@onready var player = $Player
@onready var enemy_spawns = $EnemySpawnNodes/EnemySpawns
@onready var navigation_region = $NavigationRegion3D


var enemy = load("res://Scenes/enemy.tscn")
var instance 

# Creates a seed for a random number generator
func _ready():
	randomize()

# Direct agents in group "enemies" to the player
func _physics_process(delta):
	get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)
	

# Get a random spawn point that is a child to the "EnemySpawns" node
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

# When timer ends signal to instansiate new enemy
func _on_enemy_spawn_timer_timeout():
	var spawn_point = _get_random_child(enemy_spawns).global_position
	instance = enemy.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)
	print("Enemy spawned")
