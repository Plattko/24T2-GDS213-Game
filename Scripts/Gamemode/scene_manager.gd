class_name SceneManager
extends Node3D

#var multiplayer_player = load("res://Scenes/Multiplayer/multiplayer_player.tscn")

@export_group("Spawning Players")
@export var players_node : Node
@export var initial_spawn_points : Array[Node3D] = []
var players_spawned : int = 0

@export_group("Zone Variables")
@export var zones : Array[Zone] = []
@export var zone_nav_regions : Array[NavigationRegion3D] = []
@export var cur_respawn_point : Vector3
var cur_zone : int = 1

@export_group("Gamemode Variables")
@export var wave_manager : WaveManager

@export_group("Game Over")
@export var map_camera : Camera3D
@export var fade_to_black : FadeToBlackTransition
@export var game_over_menu : GameOverMenu

@export var zone_swap_music_player : AudioStreamPlayer

func _ready() -> void:
	print("CALLED READY IN SCENE MANAGER.")
	if !multiplayer.is_server(): return
	
	wave_manager.game_over_entered.connect(on_game_over)
	fade_to_black.anim_player.animation_finished.connect(on_fade_to_black_animation_finished)
	
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
	print("Called spawn players.")
	# Set up an array to use for the Wave Manager
	var players_array : Array[MultiplayerPlayer] = []
	# Spawn a player for each player ID in the players dictionary
	for player_id in players:
		# Instantiate the player
		var player = load("res://Scenes/Multiplayer/multiplayer_player.tscn").instantiate() as MultiplayerPlayer
		# Set the player object's name to the player's ID
		player.name = str(player_id)
		# Make the player invisible
		player.visible = false
		# Add the player as a child of the level
		players_node.add_child(player)
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
		# Make the player visible
		player.visible = true
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
	# Update the active nav mesh
	if cur_zone == 1:
		zone_nav_regions[1].enabled = false
		zone_nav_regions[0].enabled = true
	elif cur_zone == 2:
		zone_nav_regions[0].enabled = false
		zone_nav_regions[1].enabled = true

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

#-------------------------------------------------------------------------------
# Removing Players
#-------------------------------------------------------------------------------
func remove_player(player_id: int) -> void:
	# If a player node's name is the same as the disconnected peer's ID, remove that node from the level
	for player_node in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player_node) and player_node.name.to_int() == player_id:
			player_node.queue_free()
	# Remove the player in the wave manager
	wave_manager.remove_player()
	# Remove the player in the game over menu
	game_over_menu.remove_player(player_id)

#-------------------------------------------------------------------------------
# Game Over
#-------------------------------------------------------------------------------
func on_game_over() -> void:
	# Play the fade to black animation
	fade_to_black.show()
	fade_to_black.play.rpc()

func on_fade_to_black_animation_finished(_anim_name: String) -> void:
	# Set the player's camera to the map camera
	map_camera.current = true
	# Delete the players
	if multiplayer.is_server():
		for player in wave_manager.players:
			if is_instance_valid(player):
				player.queue_free()
	# Set the game over menu's game stats text
	game_over_menu.init(wave_manager.waves_survived, wave_manager.robots_killed, wave_manager.zone_swaps)
	# Hide the fade to black
	fade_to_black.hide()
	# Show the Game Over Menu
	game_over_menu.show()
	# Give the player control of their mouse
	give_mouse_control.rpc()

@rpc("any_peer", "call_local")
func give_mouse_control() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
