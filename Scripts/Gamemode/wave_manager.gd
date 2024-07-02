class_name WaveManager

extends Node

@export var enemies_node : Node
@export var enemy_spawn_points : Array[Node3D] = []

var player : MultiplayerPlayer

const ROBOT = preload("res://Scenes/Enemies/robot.tscn")

# Wave variables
var first_wave_delay := 5.0
var intermission_delay := 5.0

var cur_wave := 1

var max_enemies := 5
var alive_enemies := 0
var enemy_spawn_delay := 1.0

signal enemy_count_updated(enemy_count: int)
signal cur_wave_updated(wave: int)
signal intermission_entered

func _ready() -> void:
	set_physics_process(false)

func initialise(player_ref) -> void: # Called by Scene Manager
	# Set player reference
	player = player_ref
	# Wait for the first wave delay
	await get_tree().create_timer(first_wave_delay).timeout
	# Spawn the first wave
	spawn_wave()
	# Enable physics process
	set_physics_process(true)

func _physics_process(_delta):
	if !multiplayer.is_server(): return
	# Direct agents in group "enemies" to the player
	get_tree().call_group("enemies", "update_target_location", player.global_transform.origin) #TODO: Make not a single player

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
	# Give enemy reference to player
	enemy.initialise(player)
	# Connect to the enemy's enemy_defeated signal
	enemy.enemy_defeated.connect(on_enemy_defeated)
	# Add enemy as child of nav region
	enemies_node.add_child(enemy, true)
	# Set enemy's spawn point to a random spawn point
	var spawn_point = enemy_spawn_points.pick_random().global_position
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
	await get_tree().create_timer(intermission_delay).timeout
	start_new_wave()

func start_new_wave() -> void:
	cur_wave += 1
	max_enemies = cur_wave * 5
	print("Max enemies: " + str(max_enemies))
	spawn_wave()

#------------------------------------RPCS---------------------------------------
@rpc("call_local")
func emit_cur_wave_updated(wave_num: int) -> void:
	cur_wave_updated.emit(wave_num)

@rpc("call_local")
func emit_enemy_count_updated(enemy_count: int) -> void:
	enemy_count_updated.emit(enemy_count)

@rpc("call_local")
func emit_intermission_entered() -> void:
	intermission_entered.emit()
