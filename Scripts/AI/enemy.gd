extends CharacterBody3D


@onready var nav_agent = $NavigationAgent3D

var SPEED = 3.0

# Set new velocity 
func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * SPEED
	
	nav_agent.set_velocity(new_velocity)

# Move agent towards target
func update_target_location(target_location):
	nav_agent.set_target_position(target_location)

# Signal for handling when enemy is close to player
func _on_navigation_agent_3d_target_reached():
	print("player in enemy attack range")

# Signal for handling avoidance behavior with other agents
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()
