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
	

# Get a list of spawn points that are not visible on screen
func _get_available_spawn_points():
	var available_spawn_points = [] # Create an empty array to hold all of the available spawn points 
	for i in range(enemy_spawns.get_child_count()): # Loop through each child of the "enemy_spawns node"
		var spawn_point = enemy_spawns.get_child(i) 
		if spawn_point.is_available_for_spawn(): # Checks if the spawn point is not visible on screen
			available_spawn_points.append(spawn_point) # If not visible then add it to the list of available spawn points 
	return available_spawn_points # Return the list of spawn points

# When timer ends signal to instantiate new enemy at any available spawn points or print "no available spawn points"
func _on_enemy_spawn_timer_timeout():
	var available_spawn_points = _get_available_spawn_points() # Get the list of any available spawn points
	if available_spawn_points.size() > 0:
		var random_id = randi() % available_spawn_points.size() # Get a random index from the available spawn points
		var spawn_point = available_spawn_points[random_id].global_position # Get the global position of the randomly selected spawn point 
		instance = enemy.instantiate()
		instance.position = spawn_point
		navigation_region.add_child(instance)
		print("Enemy spawned")
	else:
		print("No available spawn points")
