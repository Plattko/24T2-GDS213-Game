extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

# Movement variables
var min_speed := 3.0
var max_speed := 6.0
var speed

# Health variables
var max_health := 100
var cur_health

var damage := 20

signal enemy_defeated

func _ready():
	cur_health = max_health
	speed = randf_range(min_speed, max_speed)
	print("Enemy Speed: " + str(speed))
	
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)
		else:
			push_warning("Object contains non-damageable child node.")

# Set new velocity 
func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	nav_agent.set_velocity(new_velocity)
	
	if cur_health <= 0:
		enemy_defeated.emit()
		queue_free()

# Move agent towards target
func update_target_location(target_location):
	nav_agent.set_target_position(target_location)

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
