extends CharacterBody3D

@export var hurtboxes : Array[Damageable] = []

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer

var anim_state_machine
var player : MultiplayerPlayer

# Movement variables
var min_speed := 4.0
var max_speed := 7.0
var speed

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
	anim_state_machine = anim_tree.get("parameters/playback")
	# Set the enemy to max health
	cur_health = max_health
	# Give the enemy a random speed
	speed = randf_range(min_speed, max_speed)
	
	# Connect each Damageable to the on_damaged signal
	for hurtbox in hurtboxes:
		if hurtbox is Damageable:
			hurtbox.damaged.connect(on_damaged)
	
	#if !multiplayer.is_server():
		#set_physics_process(false)

func initialise(player_ref : MultiplayerPlayer):
	player = player_ref

func _physics_process(delta):
	if multiplayer.is_server():
		var cur_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		var new_velocity = (next_location - cur_location).normalized() * speed
		nav_agent.set_velocity(new_velocity)
		
		# Make enemy look at player
		var cur_velocity = Vector2(velocity.x, velocity.z).length()
		if cur_velocity > 0.01:
			look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		
		# Apply gravity when in the air
		if !is_on_floor():
			velocity.y -= 18 * delta
		
		# Kill the enemy when they reach 0 health
		if cur_health <= 0:
			enemy_defeated.emit()
			queue_free()
		
		if _target_in_range():
			animate(Animations.ATTACK)
		else:
			animate(Animations.RUN)
	else:
		animate(cur_anim)
	
	#anim_tree.set("parameters/conditions/attack", _target_in_range())
	#anim_tree.set("parameters/conditions/run", !_target_in_range())
	##anim_tree.get("parameters/playback")

func animate(anim: Animations) -> void:
	cur_anim = anim
	
	match cur_anim:
		Animations.RUN:
			anim_tree.set("parameters/conditions/run", true)
			anim_tree.set("parameters/conditions/attack", false)
		Animations.ATTACK:
			anim_tree.set("parameters/conditions/run", false)
			anim_tree.set("parameters/conditions/attack", true)

# Move agent towards target
func update_target_location(target_location):
	if anim_state_machine.get_current_node() == "Run":
		nav_agent.set_target_position(target_location)

# Signal for handling avoidance behavior with other agents
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25) # NOTE: DO NOT CHANGE!!!
	move_and_slide()

func on_damaged(damage: float):
	cur_health -= damage
	#cur_state = STUNNED

#--------------------------------ATTACKING--------------------------------------
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
