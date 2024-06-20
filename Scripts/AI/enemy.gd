extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var animation_tree = $AnimationTree

const ATTACK_RANGE = 1.5

# Movement variables
var min_speed := 4.0
var max_speed := 7.0
var speed

var player : Player

var anim_state_machine

# Health variables
var max_health := 100
var cur_health

var damage := 20

signal enemy_defeated

func _ready():
	anim_state_machine = animation_tree.get("parameters/playback")
	cur_health = max_health
	speed = randf_range(min_speed, max_speed)
	
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)
		else:
			push_warning("Object contains non-damageable child node.")

# Set new velocity 
func _physics_process(delta):
	
	match anim_state_machine.get_current_node():
		"Run":
			var current_location = global_transform.origin
			var next_location = nav_agent.get_next_path_position()
			var new_velocity = (next_location - current_location).normalized() * speed
			nav_agent.set_velocity(new_velocity)
			look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		"Attack":
			nav_agent.set_velocity(Vector3.ZERO)
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	
	animation_tree.set("parameters/conditions/attack", _target_in_range())
	animation_tree.set("parameters/conditions/run", !_target_in_range())
	
	animation_tree.get("parameters/playback")
	
	if cur_health <= 0:
		enemy_defeated.emit()
		queue_free()

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

# Move agent towards target
func update_target_location(target_location):
	if anim_state_machine.get_current_node() == "Run":
		nav_agent.set_target_position(target_location)

func initialise(player_ref : Player):
	player = player_ref
	

# Signal for handling when enemy is close to player
func _on_navigation_agent_3d_target_reached():
	pass

# Signal for handling avoidance behavior with other agents
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()

func on_damaged(damage: float):
	cur_health -= damage

func _on_area_3d_area_entered(area):
	if area.name == "Damageable":
		area.take_damage(damage)
		print ("DEAL DAMAGE")

func _on_enemy_defeated():
	pass

func _hit_finished():
	var children = player.get_children()
	for child in children:
		if child.name == "Damageable":
			child.take_damage(damage)
