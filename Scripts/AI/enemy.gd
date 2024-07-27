class_name Enemy
extends CharacterBody3D

@export var collider : CollisionShape3D
@export var hurtboxes : Array[Damageable] = []
@export var nav_agent : NavigationAgent3D
@export var anim_tree : AnimationTree
@export var health_bar : EnemyHealthBar

@export var health_orb_scene = preload("res://Scenes/Pickups/health_orb.tscn")

var anim_state_machine : AnimationNodeStateMachinePlayback
var player : MultiplayerPlayer

# Movement variables
var min_speed := 4.0
var max_speed := 7.0
var speed : float

# Target tracking variables
@export var target_timer : Timer
var target_position : Vector3
var dist_threshold := 0.5
var is_initial_call := true

# Health variables
var max_health := 100
var cur_health

var health_drop_chance : float = 0.2

# Attack variables
const ATTACK_RANGE := 1.75
var atk_damage := 20
var has_attack_hit := false

# Animation variables
enum Animations { RUN, ATTACK, STUNNED, CLIMB, DEAD }
var cur_anim

# State Machine variables
@export_group("State Machine Variables")
@export var state_machine : EnemyStateMachine

signal enemy_defeated

func _ready():
	if multiplayer.is_server():
		# Get animation state machine
		anim_state_machine = anim_tree.get("parameters/playback")
		# Activate animation tree
		anim_tree.active = true
		# Initialise state machine
		state_machine.init(self)
		
		# Give the enemy a random speed
		speed = randf_range(min_speed, max_speed)
		print("Enemy speed: " +str(speed))
		# Connect the target timer's timeout signal to the set_target_position function
		target_timer.timeout.connect(set_target_position)
		# Set the initial target location
		target_position = player.global_position
		set_target_position()
	
	# Set the enemy to max health
	cur_health = max_health
	# Initialise the health bar
	health_bar.init_health(cur_health)
	# Connect each Damageable to the on_damaged signal
	for hurtbox in hurtboxes:
		if hurtbox is Damageable:
			hurtbox.damaged.connect(on_damaged)

func initialise(_player : MultiplayerPlayer):
	player = _player

func _physics_process(_delta):
	if multiplayer.is_server():
		if cur_health <= 0:
			die()

#-------------------------------------------------------------------------------
# Movement
#-------------------------------------------------------------------------------
# Set the navigation agent's target position to the player position
func set_target_position() -> void:
	await get_tree().physics_frame
	if player:
		if Vector3(player.global_position - target_position).length() > dist_threshold or is_initial_call:
			if is_initial_call: is_initial_call = false
			#if anim_state_machine.get_current_node() == "Attack": return
			target_position = player.global_position
			nav_agent.set_target_position(target_position)

# Signal for handling avoidance behavior with other agents
func _on_nav_agent_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25) # NOTE: DO NOT CHANGE!!!
	move_and_slide()

#-------------------------------------------------------------------------------
# Animation
#-------------------------------------------------------------------------------
func animate(anim: Animations) -> void:
	cur_anim = anim
	
	match cur_anim:
		Animations.RUN:
			anim_state_machine.travel("Run")
		Animations.ATTACK:
			anim_state_machine.travel("Attack", true)

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
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
		level.add_child(health_orb)
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
	print("Reset has_attack_hit.")

func _on_attack_hitbox_area_entered(area) -> void:
	if area is Damageable and !has_attack_hit:
		print("%s hit." % area)
		area.take_damage(atk_damage, false)

func _on_attack_hitbox_area_exited(area) -> void:
	if area is Damageable:
		has_attack_hit = true
		print("Attack has hit.")

#-------------------------------------------------------------------------------
# Debugging
#-------------------------------------------------------------------------------
func _on_nav_agent_path_changed():
	#print("Path changed.")
	pass
