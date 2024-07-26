class_name SceneManager
extends Node3D

var multiplayer_player = preload("res://Scenes/Multiplayer/multiplayer_player.tscn")

@export_group("Initial Spawn Points")
@export var initial_spawn_points : Array[Node3D] = []

# Zone variables
@export_group("Zone Variables")
#@export var zone_respawn_points : Array[Node3D] = []
@export var zones : Array[Zone] = []
var cur_zone : int = 1

#@export var vaporisation_zones : Array[Node] = []
#@export var vaporisation_beams : Array[MeshInstance3D] = []

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
	
	#for zone in vaporisation_zones:
		#for area in zone.get_children():
			#if area is Area3D:
				#area.body_entered.connect(body_in_vaporisation_area)
				#print("Vaporisation area connected.")
			#else:
				#print("Non-area node detected in Vaporisation Zone.")
	
	# Spawn the players
	for i in GameManager.players:
		var player = multiplayer_player.instantiate()
		# Set the player's name to their unique ID
		player.name = str(GameManager.players[i].id)
		# Add the player as a child of the scene
		add_child(player)
		# Check if it's player 1
		if GameManager.players[i].player_num == 1:
			# Manually set their initial spawn point
			set_initial_spawn_point(player)
			# [NOTE - TEMPORARY] Give the Wave Manager a reference to the player
			if wave_manager: wave_manager.initialise(player)
		
		#TODO: Connect the UI to the player
	
	# Set the current respawn point
	set_respawn_point.rpc()

## Temporary fix TODO: Make work differently
func _on_multiplayer_spawner_spawned(node):
	print("Spawned player " + str(node.name) + " on client " + str(multiplayer.get_unique_id()))
	set_initial_spawn_point(node)

func set_initial_spawn_point(player) -> void:
	# Only set the spawn point if its the client's player
	if player.name.to_int() == multiplayer.get_unique_id():
		# Set the player's position to their respective spawn point
		var player_num = GameManager.players[player.name.to_int()].player_num
		player.global_position = initial_spawn_points[player_num - 1].global_position
		print("Player " + str(player_num) + " position: " + str(player.global_position))

func vaporise_zone() -> void:
	zones[cur_zone - 1].vaporisation_beam.get_child(0).play("Strike")
	
	#vaporisation_beams[cur_zone - 1].get_child(0).play("Strike")
	update_zone()

func update_zone() -> void:
	if cur_zone == 1:
		cur_zone = 2
	elif cur_zone == 2:
		cur_zone = 1
	set_respawn_point.rpc()

func body_in_vaporisation_area(body: Node3D) -> void:
	if body is Enemy:
		body.queue_free()
		print("Enemy vaporised.")
	elif body is MultiplayerPlayer:
		# TODO: Update to not respawn player for respawn time
		body.respawn_player()
		print("Player vaporised.")

func get_enemy_spawn_points() -> Array[Node3D]:
	var spawn_points : Array[Node3D] = []
	for spawn_point in zones[cur_zone - 1].enemy_spawn_points.get_children():
		spawn_points.append(spawn_point)
	return spawn_points

@rpc("any_peer", "call_local")
func set_respawn_point() -> void:
	GameManager.cur_respawn_point = zones[cur_zone - 1].respawn_point.global_position
	
	#GameManager.cur_respawn_point = zone_respawn_points[cur_zone - 1].global_position
