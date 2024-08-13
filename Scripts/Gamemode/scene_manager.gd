class_name SceneManager
extends Node3D

var multiplayer_player = load("res://Scenes/Multiplayer/multiplayer_player.tscn")

@export_group("Initial Spawn Points")
@export var initial_spawn_points : Array[Node3D] = []
var players_spawned : int = 0

# Zone variables
@export_group("Zone Variables")
@export var zones : Array[Zone] = []
var cur_zone : int = 1
@export var cur_respawn_point : Vector3

# Gamemode variables
@export_group("Gamemode Variables")
@export var wave_manager : WaveManager

func _ready() -> void:
	if !multiplayer.is_server(): return
	
	#TODO: Instantiate the UI
	
	# Connect vaporisation areas
	for zone in zones:
		for area in zone.vaporisation_areas.get_children():
			if area is Area3D:
				area.body_entered.connect(body_in_vaporisation_area)
				print("Vaporisation area connected.")
			else:
				print("Non-area node detected in Vaporisation Zone.")

func spawn_players(players: Dictionary = {}) -> void:
	# Set up an array to use for the Wave Manager
	var players_array : Array[MultiplayerPlayer] = []
	# Spawn a player for each player ID in the players dictionary
	for player_id in players:
		# Instantiate the player
		var player = multiplayer_player.instantiate() as MultiplayerPlayer
		# Set the player object's name to the player's ID
		player.name = str(player_id)
		# Add the player as a child of the level
		add_child(player)
		# Manually set the host's initial spawn point
		if player_id == 1: set_initial_spawn_point(player)
		# Add them to the players array
		players_array.append(player)
	# Set up the Wave Manager
	if wave_manager:
		# Set the alive players to the number of players
		wave_manager.alive_player_count = players.size()
		# Give it a reference to the scene manager and the players array
		wave_manager.initialise(self, players_array)
	# Set the current respawn point
	set_respawn_point.rpc(cur_zone)

## Temporary fix TODO: Make work differently
func _on_multiplayer_spawner_spawned(node):
	print("Spawned player " + str(node.name) + " on client " + str(multiplayer.get_unique_id()))
	set_initial_spawn_point(node)

func set_initial_spawn_point(player) -> void:
	# Only set the spawn point if its the client's player
	if player.name.to_int() == multiplayer.get_unique_id():
		# Set the player's position to their respective spawn point
		player.global_position = initial_spawn_points[players_spawned].global_position
	# Increased the players spawned count by 1
	players_spawned += 1
	print("Players spawned: " + str(players_spawned))

func vaporise_zone() -> void:
	#zones[cur_zone - 1].vaporisation_beam.get_child(0).play("Strike")
	play_anim.rpc(cur_zone, "Strike")
	
	update_zone()

func vaporise_enemies() -> void:
	# Only run by the server
	if !multiplayer.is_server(): return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
		print("Enemy vaporised.")

func update_zone() -> void:
	if cur_zone == 1:
		cur_zone = 2
	elif cur_zone == 2:
		cur_zone = 1
	set_respawn_point.rpc(cur_zone)

func body_in_vaporisation_area(body: Node3D) -> void:
	if body is MultiplayerPlayer:
		# TODO: Update to not respawn player for respawn time
		body.die.rpc_id(body.name.to_int(), true)
		print("Player vaporised.")

func get_enemy_spawn_points() -> Array[Node3D]:
	var spawn_points : Array[Node3D] = []
	for spawn_point in zones[cur_zone - 1].enemy_spawn_points.get_children():
		spawn_points.append(spawn_point)
	return spawn_points

@rpc("call_local")
func play_anim(_cur_zone: int, anim: String) -> void:
	var anim_player = zones[_cur_zone - 1].vaporisation_beam.get_child(0)
	anim_player.play(anim)

@rpc("any_peer", "call_local")
func set_respawn_point(_cur_zone: int) -> void:
	cur_respawn_point = zones[_cur_zone - 1].respawn_point.global_position
