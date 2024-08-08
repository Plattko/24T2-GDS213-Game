class_name WaveManager
extends Node

const ROBOT = preload("res://Scenes/Enemies/robot_regular.tscn")
const SPEEDY_ROBOT = preload("res://Scenes/Enemies/robot_speedy.tscn")
var player : MultiplayerPlayer

@export_group("Reference Variables")
@export var intermission_timer : Timer
@export var zone_change_timer : Timer
@export var endless_wave_timer : Timer
@export var enemies_node : Node
@export var zone_gate : ZoneGate
var scene_manager : SceneManager

@export_group("Wave Variables")
@export var waves_enabled : bool = true

var first_wave_delay := 5.0
var cur_wave := 1

@export var initial_max_enemies : int = 5
@export var max_enemy_multiplier : int = 5
@export var do_enemy_count_hard_cap : bool = true
@export var enemy_count_hard_cap : int = 15
var max_enemies : int
var alive_enemies := 0
var enemy_spawn_delay := 1.0

@export_range(0.0, 1.0, 0.01) var speedy_robot_chance : float = 0.33

@export_group("Zone Change Variables")
@export var zone_changes_enabled : bool = true
@export var do_immediate_zone_change : bool = false
@export var change_possible_index : int = 4
var wave_index : int = 0
var cur_change_chance : float = 0.0
var change_chance_increase : float = 0.2
var zone_change_duration : float = 30.0
var do_zone_change : bool = false

@export_group("Player Variables")
@export var alive_player_count : int = 1:
	set(value):
		alive_player_count = value
		print("Alive players: " + str(alive_player_count))
		if alive_player_count <= 0 and multiplayer.is_server:
			await get_tree().create_timer(3.0).timeout
			game_over.rpc()

# Game over variables
var game_over_menu_scene = load("res://Scenes/UI/Menus/game_over_menu.tscn")
var fade_to_black_transition_scene = load("res://UI/fade_to_black_transition.tscn")

signal enemy_count_updated(enemy_count: int)
signal cur_wave_updated(wave: int)
signal intermission_entered
signal zone_change_entered

func _ready() -> void:
	if !multiplayer.is_server(): return
	randomize()
	handle_connected_signals()

#-------------------------------------------------------------------------------
# Waves
#-------------------------------------------------------------------------------
func spawn_wave() -> void:
	print("WAVE STARTED")
	# Set the number of alive enemies to the max enemies
	alive_enemies = max_enemies
	# Update the current wave and enemy count on the UI
	emit_cur_wave_updated.rpc(cur_wave)
	emit_enemy_count_updated.rpc(alive_enemies)
	# Spawn a number of enemies equal to the max enemies
	for n in max_enemies:
		# Wait for enemy delay
		await get_tree().create_timer(enemy_spawn_delay).timeout
		# Spawn an enemy
		spawn_enemy(false)

func start_intermission() -> void:
	print("INTERMISSION STARTED")
	# Update the HUD to display that it's an intermission
	emit_intermission_entered.rpc()
	# Update zone change variables
	wave_index += 1
	#print("Wave index: " + str(wave_index))
	if wave_index >= change_possible_index:
		cur_change_chance += change_chance_increase
		#print("Current zone change chance: " + str(cur_change_chance))
		var roll := randf_range(0.0, 1.0)
		if roll <= cur_change_chance:
			do_zone_change = true
	# Wait for the intermission timer to end and start a new wave or a zone change sequence
	await intermission_timer.timeout
	if zone_changes_enabled and (do_zone_change or do_immediate_zone_change):
		start_zone_change()
	else:
		start_new_wave()

func start_new_wave() -> void:
	# Increase the current wave number
	cur_wave += 1
	# Set the max enemies to the current wave multiplied by the max enemy multiplier
	max_enemies = cur_wave * max_enemy_multiplier
	# Clamp the max enemies to the enemy count hard cap
	if do_enemy_count_hard_cap: max_enemies = clampi(max_enemies, 0, enemy_count_hard_cap)
	# Spawn the wave
	spawn_wave()

#-------------------------------------------------------------------------------
# Enemies
#-------------------------------------------------------------------------------
func spawn_enemy(is_endless_wave: bool) -> void:
	# Instantiate enemy
	var enemy
	if !is_endless_wave:
		var roll := randf_range(0.0, 1.0)
		# Roll for whether it is a regular or speedy enemy
		if roll <= speedy_robot_chance:
			enemy = SPEEDY_ROBOT.instantiate()
		else:
			enemy = ROBOT.instantiate()
	else:
		enemy = ROBOT.instantiate()
	# Initialise enemy
	var nav_layer = scene_manager.cur_zone
	enemy.initialise(player, nav_layer)
	# Connect to the enemy's enemy_defeated signal if it is a regular wave
	if !is_endless_wave: enemy.enemy_defeated.connect(on_enemy_defeated)
	# Add enemy as child of nav region
	enemies_node.add_child(enemy, true)
	# Set enemy's spawn point to a random spawn point
	var spawn_point = pick_random_spawn_point()
	enemy.global_position = spawn_point

func pick_random_spawn_point() -> Vector3:
	var spawn_points = scene_manager.get_enemy_spawn_points()
	return spawn_points.pick_random().global_position

func on_enemy_defeated() -> void:
	print("Enemy defeated!")
	# Reduce enemies by 1
	alive_enemies -= 1
	emit_enemy_count_updated.rpc(alive_enemies)
	#print("Enemies alive: " + str(alive_enemies) + "/" + str(max_enemies))
	
	if alive_enemies <= 0:
		start_intermission()
		#print("INTERMISSION STARTED")
#-------------------------------------------------------------------------------
# Initialisation
#-------------------------------------------------------------------------------
func handle_connected_signals() -> void:
	zone_gate.anim_player.animation_finished.connect(_on_zone_gate_anim_finished)

# Called by Scene Manager
func initialise(_scene_manager: SceneManager, _player: MultiplayerPlayer) -> void:
	# Set scene manager reference
	scene_manager = _scene_manager
	# Set player reference
	player = _player
	# Start the waves
	if waves_enabled:
		# Set the max enemies to the initial max enemies
		max_enemies = initial_max_enemies
		# Wait for the first wave delay
		await get_tree().create_timer(first_wave_delay).timeout
		# Spawn the first wave
		spawn_wave()

#-------------------------------------------------------------------------------
# Zone Change Sequence
#-------------------------------------------------------------------------------
func start_zone_change() -> void:
	print("ZONE CHANGE STARTED")
	# Reset zone change variables
	wave_index = 0
	cur_change_chance = 0.0
	if do_zone_change: do_zone_change = false
	if do_immediate_zone_change: do_immediate_zone_change = false
	
	# Start the endless wave
	endless_wave_timer.start()
	
	# Display zone change warning UI
	emit_zone_change_entered.rpc()
	# Play zone gate open animation
	zone_gate.anim_player.play("Open")

func _on_zone_gate_anim_finished(anim_name: StringName) -> void:
	if anim_name == "Open":
		print("ZONE GATE OPENED")
		# Start gate close animation
		zone_gate.anim_player.play("Close")
	elif anim_name == "Close":
		print("ZONE GATE CLOSED")
		# Stop the endless wave
		endless_wave_timer.stop()
		
		# TODO: Play screen shake
		
		# Play the vaporisation ray animation
		scene_manager.vaporise_zone()
		
		# TODO: Start new wave without respawning players
		await get_tree().create_timer(3.0).timeout
		start_new_wave()

func _on_endless_wave_timer_timeout():
	print("ENDLESS WAVE TIMER TIMED OUT")
	# Restart the timer
	endless_wave_timer.start()
	# Spawn a new enemy if there are less than 15 currently alive
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	if enemy_count < 15:
		spawn_enemy(true)

#-------------------------------------------------------------------------------
# RPCS
#-------------------------------------------------------------------------------
@rpc("call_local")
func emit_cur_wave_updated(wave_num: int) -> void:
	cur_wave_updated.emit(wave_num)

@rpc("call_local")
func emit_enemy_count_updated(enemy_count: int) -> void:
	enemy_count_updated.emit(enemy_count)

@rpc("call_local")
func emit_intermission_entered() -> void:
	intermission_timer.start()
	intermission_entered.emit()

@rpc("call_local")
func emit_zone_change_entered() -> void:
	zone_change_timer.start()
	zone_change_entered.emit()

@rpc("any_peer", "call_local")
func on_player_died() -> void:
	alive_player_count -= 1

@rpc("any_peer", "call_local")
func on_player_respawned() -> void:
	alive_player_count += 1

@rpc("call_local")
func game_over() -> void:
	print("GAME OVER")
	var level = get_tree().get_first_node_in_group("level")
	# Instantiate the fade to black transition
	var fade = fade_to_black_transition_scene.instantiate() as FadeToBlackTransition
	# Add it as a child of the level
	level.add_child(fade)
	fade.anim_player.animation_finished.connect(change_to_game_over_menu)
	## Wait for the fade to black animation to end
	#await fade.anim_player.animation_finished
	## Instantiate the game over menu
	#var game_over_menu = game_over_menu_scene.instantiate()
	## Add it as a child of the level's parent
	#level.get_parent().add_child(game_over_menu)
	## Delete the level
	#level.queue_free()
	## Show the mouse
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func change_to_game_over_menu(_anim_name: StringName) -> void:
	# Instantiate the game over menu
	var game_over_menu = game_over_menu_scene.instantiate()
	# Add it as a child of the level's parent
	var level = get_tree().get_first_node_in_group("level")
	level.get_parent().add_child(game_over_menu)
	# Delete the level
	level.queue_free()
	# Show the mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
