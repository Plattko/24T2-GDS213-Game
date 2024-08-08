class_name JumpEnemyState
extends EnemyState

var start_pos : Vector3
var end_pos : Vector3
var mid_pos : Vector3

var jump_clearance : float = 1
var jump_speed_mod : float = 1.5
var jump_time : float

func enter(msg : Dictionary = {}) -> void:
	# Only run by the server
	if !multiplayer.is_server(): return
	# Play the jump animation
	enemy.animate.rpc(enemy.Animations.JUMP)
	
	if !msg.link_exit_position or !msg.link_entry_position:
		printerr("Missing navigation entry or exit position.")
	
	# Look in direction of jump
	enemy.look_at(Vector3(msg.link_exit_position.x, enemy.global_position.y, msg.link_exit_position.z), Vector3.UP)
	
	# Set bezier curve points
	start_pos = msg.link_entry_position + Vector3.UP * enemy.collider.shape.height
	end_pos = msg.link_exit_position + Vector3.UP * enemy.collider.shape.height
	#print("Start position: " + str(start_pos))
	#print("End position: " + str(end_pos))
	mid_pos = ((end_pos - start_pos) * 0.5 + start_pos)
	var peak_height := maxf(start_pos.y + jump_clearance, end_pos.y + jump_clearance)
	mid_pos.y = peak_height
	
	# Set jump time
	var jump_dist = (end_pos - start_pos).length()
	var jump_speed = enemy.speed * jump_speed_mod
	jump_time = jump_dist / jump_speed
	
	# Start jump
	tween_jump()

func tween_jump() -> void:
	# Create a tween to track the progress of the jump arc
	var tween = get_tree().create_tween()
	await tween.tween_method(jump, 0.0, 1.0, jump_time).finished
	enemy.velocity = Vector3.ZERO
	transition.emit("RunEnemyState")

func jump(progress: float) -> void:
	# Calculate jump arc with bezier curve formula
	var q0 = start_pos.lerp(mid_pos, progress)
	var q1 = mid_pos.lerp(end_pos, progress)
	var jump_pos = q0.lerp(q1, progress)
	# Set enemy position to the position in the jump arc
	enemy.position = jump_pos
