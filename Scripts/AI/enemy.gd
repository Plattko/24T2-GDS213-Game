extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var animation_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer

var anim_state_machine
var player : Player

enum {
	RUNNING,
	ATTACKING,
	STUNNED,
	CLIMBING,
	DEAD
}

var state = RUNNING

# Movement variables
var min_speed := 4.0
var max_speed := 7.0
var speed

# Health variables
var max_health := 100
var cur_health

# Attack variables
const ATTACK_RANGE = 1.5
var atk_damage := 20

signal enemy_defeated

func _ready():
	anim_state_machine = animation_tree.get("parameters/playback")
	cur_health = max_health
	speed = randf_range(min_speed, max_speed)
	
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)
		#else:
			#push_warning("Object contains non-damageable child node.")

func _process(delta):
	match state:
		RUNNING:
			animation_player.play("Run")
		ATTACKING:
			animation_player.play("Attack")
		STUNNED:
			pass
		CLIMBING:
			pass
		DEAD:
			pass

# Set new velocity 
func _physics_process(delta):
	
	match anim_state_machine.get_current_node():
		"Run":
			var current_location = global_transform.origin
			var next_location = nav_agent.get_next_path_position()
			var new_velocity = (next_location - current_location).normalized() * speed
			nav_agent.set_velocity(new_velocity)
			
			var cur_velocity = Vector2(velocity.x, velocity.z).length()
			if cur_velocity > 0.01:
				look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		"Attack":
			nav_agent.set_velocity(Vector3.ZERO)
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	if !is_on_floor():
		velocity.y -= 18 * delta
	
	
	animation_tree.set("parameters/conditions/attack", _target_in_range())
	animation_tree.set("parameters/conditions/run", !_target_in_range())
	
	animation_tree.get("parameters/playback")
	
	if cur_health <= 0:
		enemy_defeated.emit()
		queue_free()

func initialise(player_ref : Player):
	player = player_ref

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

# Move agent towards target
func update_target_location(target_location):
	if anim_state_machine.get_current_node() == "Run":
		nav_agent.set_target_position(target_location)

# Signal for handling when enemy is close to player
func _on_navigation_agent_3d_target_reached():
	pass

# Signal for handling avoidance behavior with other agents
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.10)
	move_and_slide()

func on_damaged(damage: float):
	cur_health -= damage

func _hit_finished():
	var children = player.get_children()
	for child in children:
		if child.name == "Damageable":
			child.take_damage(atk_damage)
