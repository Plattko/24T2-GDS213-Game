extends CharacterBody3D

@export var hurtboxes : Array[Damageable] = []

@onready var nav_agent = $NavigationAgent3D
@onready var animation_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer

var anim_state_machine
var player : Player

# Enemy state machine states
enum {
	RUNNING,
	ATTACKING,
	STUNNED,
	CLIMBING,
	DEAD
}

var cur_state = RUNNING

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

var has_attack_hit : bool = false

signal enemy_defeated

func _ready():
	anim_state_machine = animation_tree.get("parameters/playback")
	cur_health = max_health
	speed = randf_range(min_speed, max_speed)
	print("Speed: " + str(speed))
	
	for hurtbox in hurtboxes:
		if hurtbox is Damageable:
			# Connect each damageable to the damaged signal
			hurtbox.damaged.connect(on_damaged)

func _physics_process(delta):
	match cur_state:
		RUNNING:
			#animation_tree.set("parameters/playback", "Run")
			var current_location = global_transform.origin
			var next_location = nav_agent.get_next_path_position()
			var new_velocity = (next_location - current_location).normalized() * speed
			nav_agent.set_velocity(new_velocity)
			
			# Make enemy look at player
			var cur_velocity = Vector2(velocity.x, velocity.z).length()
			if cur_velocity > 0.01:
				look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		
		ATTACKING:
			#animation_tree.set("parameters/playback", "Attack")
			nav_agent.set_velocity(Vector3.ZERO)
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		STUNNED:
			pass # Do stunned stuff
		
		CLIMBING:
			pass # Do climbing stuff
		
		DEAD:
			pass # Do ragdoll stuff
	
	animation_tree.set("parameters/conditions/attack", _target_in_range())
	animation_tree.set("parameters/conditions/run", !_target_in_range())
	animation_tree.get("parameters/playback")
	
	if !is_on_floor():
		velocity.y -= 18 * delta
	
	if cur_health <= 0:
		enemy_defeated.emit()
		queue_free()

func initialise(player_ref : Player):
	player = player_ref

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
