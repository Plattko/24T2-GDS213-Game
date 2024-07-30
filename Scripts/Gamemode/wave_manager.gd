class_name WaveManager
extends Node

# Enemy spawning variables
@export var enemies_node : Node

var player : MultiplayerPlayer

const ROBOT = preload("res://Scenes/Enemies/robot.tscn")

@export var do_enemy_count_hard_cap : bool = true
@export var enemy_count_hard_cap : int = 15

# Wave variables
var first_wave_delay := 5.0
var intermission_delay := 5.0

var cur_wave := 1

var max_enemies := 10
var alive_enemies := 0
var enemy_spawn_delay := 1.0

# Zone change variables
@export_group("Zone Change Variables")
@export var zone_change_timer : Timer
@export var endless_wave_timer : Timer
@export var zone_gate : ZoneGate

var wave_index : int = 0
@export var change_possible_index : int = 4
var cur_change_chance : float = 0.0
var change_chance_increase : float = 0.2
var zone_change_duration : float = 30.0
@export var do_zone_change : bool = false

signal enemy_count_updated(enemy_count: int)
signal cur_wave_updated(wave: int)
signal intermission_entered
signal zone_change_entered

func _ready() -> void:
	randomize()
	
	zone_gate.anim_player.animation_finished.connect(_on_zone_gate_anim_finished)

func initialise(player_ref) -> void: # Called by Scene Manager
	# Set player reference
	player = player_ref
	# Wait for the first wave delay
	await get_tree().create_timer(first_wave_delay).timeout
	# Spawn the first wave
	spawn_wave()

func spawn_wave() -> void:
	print("WAVE STARTED")
	alive_enemies = max_enemies
	
	emit_cur_wave_updated.rpc(cur_wave)
	emit_enemy_count_updated.rpc(alive_enemies)
	
	for n in max_enemies:
		# Wait for enemy delay
		await get_tree().create_timer(enemy_spawn_delay).timeout
		# Spawn an enemy
		spawn_enemy()

func spawn_enemy() -> void:
	# Instantiate enemy
	var enemy = ROBOT.instantiate()
	# Initialise enemy
	var scene_manager = get_tree().get_first_node_in_group("level")
	var nav_layer = scene_manager.cur_zone
	enemy.initialise(player, nav_layer)
	# Connect to the enemy's enemy_defeated signal
	enemy.enemy_defeated.connect(on_enemy_defeated)
	# Add enemy as child of nav region
	enemies_node.add_child(enemy, true)
	# Set enemy's spawn point to a random spawn point
	var spawn_point = pick_random_spawn_point()
	enemy.global_position = spawn_point

func on_enemy_defeated() -> void:
	# Reduce enemies by 1
	alive_enemies -= 1
	emit_enemy_count_updated.rpc(alive_enemies)
	print("Enemies alive: " + str(alive_enemies) + "/" + str(max_enemies))
	
	if alive_enemies <= 0:
		start_intermission()
		print("INTERMISSION STARTED")

func start_intermission() -> void:
	emit_intermission_entered.rpc()
	
	# Update zone change variables
	wave_index += 1
	print("Wave index: " + str(wave_index))
	if wave_index >= change_possible_index:
		cur_change_chance += change_chance_increase
		print("Current zone change chance: " + str(cur_change_chance))
		var roll := randf_range(0.0, 1.0)
		if roll <= cur_change_chance:
			do_zone_change = true
	
	await get_tree().create_timer(intermission_delay).timeout
	if do_zone_change:
		start_zone_change()
	else:
		start_new_wave()

func start_new_wave() -> void:
	cur_wave += 1
	max_enemies = cur_wave * 5
	if do_enemy_count_hard_cap: max_enemies = clampi(max_enemies, 0, enemy_count_hard_cap)
	print("Max enemies: " + str(max_enemies))
	spawn_wave()

#-------------------------------------------------------------------------------
# Zone Change Sequence
#-------------------------------------------------------------------------------
func start_zone_change() -> void:
	# Reset zone change variables
	wave_index = 0
	cur_change_chance = 0.0
	do_zone_change = false
	
	# Start the endless wave
	endless_wave_timer.start()
	
	# Display zone change warning UI
	emit_zone_change_entered.rpc()
	# Play zone gate open animation
	zone_gate.anim_player.play("Open")

func _on_zone_gate_anim_finished(anim_name: StringName) -> void:
	if anim_name == "Open":
		# Start gate close animation
		zone_gate.anim_player.play("Close")
	elif anim_name == "Close":
		# Stop the endless wave
		endless_wave_timer.stop()
		
		# TODO: Play screen shake
		
		# TODO: Play vaporisation ray and kill all enemies/players in zone
		var scene_manager = get_tree().get_first_node_in_group("level")
		scene_manager.vaporise_zone()
		
		# TODO: Start new wave without respawning players
		await get_tree().create_timer(3.0).timeout
		start_new_wave()

func _on_endless_wave_timer_timeout():
	# Restart the timer
	endless_wave_timer.start()
	# Spawn a new enemy if there are less than 15 currently alive
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	if enemy_count < 15:
		# Instantiate enemy
		var enemy = ROBOT.instantiate()
		# Initialise enemy
		var scene_manager = get_tree().get_first_node_in_group("level")
		var nav_layer = scene_manager.cur_zone
		enemy.initialise(player, nav_layer)
		# Add enemy as child of nav region
		enemies_node.add_child(enemy, true)
		# Set enemy's spawn point to a random spawn point
		var spawn_point = pick_random_spawn_point()
		enemy.global_position = spawn_point
		print("Enemy count: " + str(enemy_count))

func pick_random_spawn_point() -> Vector3:
	var scene_manager = get_tree().get_first_node_in_group("level")
	var spawn_points = scene_manager.get_enemy_spawn_points()
	return spawn_points.pick_random().global_position

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
	intermission_entered.emit()

@rpc("call_local")
func emit_zone_change_entered() -> void:
	zone_change_timer.start()
	zone_change_entered.emit()
