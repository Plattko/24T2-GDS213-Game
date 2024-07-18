class_name Enemy
extends CharacterBody3D

@export var collider : CollisionShape3D
@export var hurtboxes : Array[Damageable] = []
@export var nav_agent : NavigationAgent3D
@export var anim_tree : AnimationTree

var anim_state_machine
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

# Attack variables
const ATTACK_RANGE := 1.75
var atk_damage := 20
var has_attack_hit := false

# Enemy state machine states
enum Animations { RUN, ATTACK, STUNNED, CLIMB, DEAD }
@export var cur_anim := Animations.RUN

signal enemy_defeated

func _ready():
	if multiplayer.is_server():
		# Give the enemy a random speed
		speed = randf_range(min_speed, max_speed)
		# Connect the target timer's timeout signal to the set_target_position function
		target_timer.timeout.connect(set_target_position)
		# Set the initial target location
		target_position = player.global_position
		set_target_position()
	
	anim_state_machine = anim_tree.get("parameters/playback")
	# Set the enemy to max health
	cur_health = max_health
	# Connect each Damageable to the on_damaged signal
	for hurtbox in hurtboxes:
		if hurtbox is Damageable:
			hurtbox.damaged.connect(on_damaged)

func initialise(player_ref : MultiplayerPlayer):
	player = player_ref

func _physics_process(delta):
	if multiplayer.is_server():
		if is_on_floor():
			# Update movement
			var cur_location : Vector3 = global_position
			var next_location : Vector3 = nav_agent.get_next_path_position()
			var new_velocity : Vector3 = (next_location - cur_location).normalized() * speed
			nav_agent.set_velocity(new_velocity)
		# Apply gravity when in the air
		else:
			velocity.y -= 18 * delta
		
		# Kill the enemy when they reach 0 health
		if cur_health <= 0:
			enemy_defeated.emit()
			queue_free()
		
		# If enemy is running
		if anim_state_machine.get_current_node() == "Run":
			# Make enemy look where they're running
			var cur_velocity = Vector2(velocity.x, velocity.z).length()
			if cur_velocity > 0.01:
				look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		# If enemy is attacking
		elif anim_state_machine.get_current_node() == "Attack":
			# Make enemy look at player
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		if _target_in_range():
			animate(Animations.ATTACK)
		else:
			animate(Animations.RUN)
	else:
		animate(cur_anim)

#-------------------------------------------------------------------------------
# Movement
#-------------------------------------------------------------------------------
# Set the navigation agent's target position to the player position
func set_target_position() -> void:
	await get_tree().physics_frame
	if player:
		if Vector3(player.global_position - target_position).length() > dist_threshold or is_initial_call:
			if is_initial_call: is_initial_call = false
			if anim_state_machine.get_current_node() == "Attack": return
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
			anim_tree.set("parameters/conditions/run", true)
			anim_tree.set("parameters/conditions/attack", false)
		Animations.ATTACK:
			anim_tree.set("parameters/conditions/run", false)
			anim_tree.set("parameters/conditions/attack", true)

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
func on_damaged(damage: float):
	cur_health -= damage
	#cur_state = STUNNED

#-------------------------------------------------------------------------------
# Attacking
#-------------------------------------------------------------------------------
func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func reset_has_attack_hit() -> void:
	has_attack_hit = false
	print("Reset has_attack_hit.")

func _on_attack_hitbox_area_entered(area) -> void:
	if area is Damageable and !has_attack_hit:
		print("%s hit." % area)
		area.take_damage(atk_damage)

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
