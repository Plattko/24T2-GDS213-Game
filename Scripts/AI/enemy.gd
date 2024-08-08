class_name Enemy
extends CharacterBody3D

enum EnemyTypes { REGULAR, SPEEDY, }
@export var enemy_type : EnemyTypes = EnemyTypes.REGULAR

@export_group("Collision Variables")
@export var collider : CollisionShape3D
@export var hurtboxes : Array[Damageable] = []

@export_group("Animation Variables")
@export var anim_tree : AnimationTree
var anim_state_machine : AnimationNodeStateMachinePlayback
enum Animations { RUN, ATTACK, JUMP, STUNNED, }
@export var cur_anim : Animations

@export_group("Movement Variables")
@export var speedy_speed := 10.0
var regular_turn_speed : float = 0.25
var speedy_turn_speed : float = 0.5
var turn_speed : float
var min_speed := 4.0
var max_speed := 7.0
var speed : float

@export_group("Navigation Variables")
@export var nav_agent : NavigationAgent3D
@export var target_timer : Timer
var target_position : Vector3
var dist_threshold := 0.5
var is_initial_call := true

@export_group("Health Variables")
@export var health_bar : EnemyHealthBar
@export var max_health := 100
var cur_health

var health_orb_scene = load("res://Scenes/Pickups/health_orb.tscn")
var health_drop_chance : float = 0.2

# Attack variables
const ATTACK_RANGE := 1.75
var atk_damage := 20
var has_attack_hit := false

@export_group("State Machine Variables")
@export var state_machine : EnemyStateMachine

var player : MultiplayerPlayer

signal enemy_defeated

func _ready():
	# Get animation state machine
	anim_state_machine = anim_tree.get("parameters/playback")
	# Activate animation tree
	anim_tree.active = true
	# Initialise state machine
	state_machine.init(self)
	
	if multiplayer.is_server():
		# Give the enemy a random speed
		if enemy_type == EnemyTypes.REGULAR:
			speed = randf_range(min_speed, max_speed)
			turn_speed = regular_turn_speed
		elif enemy_type == EnemyTypes.SPEEDY:
			speed = speedy_speed
			turn_speed = speedy_turn_speed
		# Connect the target timer's timeout signal to the set_target_position function
		target_timer.timeout.connect(set_target_position)
		# Set the initial target location
		target_position = player.global_position
		set_target_position()
		# Start the target timer
		target_timer.start()
	
	# Set the enemy to max health
	cur_health = max_health
	# Initialise the health bar
	health_bar.init_health(cur_health)
	# Connect each Damageable to the on_damaged signal
	for hurtbox in hurtboxes:
		if hurtbox is Damageable:
			hurtbox.damaged.connect(on_damaged)

func initialise(_player: MultiplayerPlayer, nav_layer: int):
	player = _player
	nav_agent.set_navigation_layer_value(nav_layer, true)

func _physics_process(_delta):
	if !multiplayer.is_server(): return
	if cur_health <= 0:
		die()

#-------------------------------------------------------------------------------
# Movement
#-------------------------------------------------------------------------------
# Set the navigation agent's target position to the player position
func set_target_position() -> void:
	await get_tree().physics_frame
	# Check there is a reference to the player
	if !player: return
	# Check if player has moved from current target position
	if (player.global_position - target_position).length() < dist_threshold and !is_initial_call: return
	# Disable is_initial_call after the first call
	if is_initial_call: is_initial_call = false
	# Update the target position
	target_position = player.global_position
	nav_agent.set_target_position(target_position)

#-------------------------------------------------------------------------------
# Animation
#-------------------------------------------------------------------------------
@rpc("any_peer", "call_local")
func animate(anim: Animations) -> void:
	cur_anim = anim
	
	match cur_anim:
		Animations.RUN:
			anim_state_machine.travel("Run")
		Animations.ATTACK:
			anim_state_machine.travel("Attack", true)
		Animations.JUMP:
			anim_state_machine.travel("Jump", true)
		Animations.STUNNED:
			anim_state_machine.travel("Stunned", true)
		_:
			print("Invalid animation.")

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
@rpc("any_peer", "call_local")
func on_damaged(damage: float, is_crit: bool):
	cur_health -= damage
	health_bar.update_health(cur_health, is_crit)

func die() -> void:
	enemy_defeated.emit()
	var roll : float = randf_range(0.0, 1.0)
	if roll <= health_drop_chance:
		# Instantiate the health orb
		var health_orb = health_orb_scene.instantiate()
		# Make it a child of the level scene
		var level = get_tree().get_first_node_in_group("level")
		level.add_child(health_orb, true)
		# Set its position
		health_orb.global_position = Vector3(global_position.x, global_position.y + 1.25, global_position.z)
	queue_free()

#-------------------------------------------------------------------------------
# Attacking
#-------------------------------------------------------------------------------
func target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func reset_has_attack_hit() -> void:
	has_attack_hit = false
	#print("Reset has_attack_hit.")

func _on_attack_hitbox_area_entered(area) -> void:
	if area is Damageable and !has_attack_hit:
		#print("%s hit." % area)
		area.take_damage(atk_damage, false)

func _on_attack_hitbox_area_exited(area) -> void:
	if area is Damageable:
		has_attack_hit = true
		#print("Attack has hit.")

#-------------------------------------------------------------------------------
# Debugging
#-------------------------------------------------------------------------------
func _on_nav_agent_path_changed():
	#print("Path changed.")
	pass
