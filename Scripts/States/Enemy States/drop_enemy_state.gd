class_name DropEnemyState
extends JumpEnemyState

var drop_height : float
var stun_time_multiplier : float = 0.1

func enter(msg: Dictionary = {}) -> void:
	# Only run by the server
	if !multiplayer.is_server(): return
	
	if !msg.height:
		printerr("Missing drop height.")
	# Set the drop height
	drop_height = msg.height
	jump_clearance = drop_height * 0.8
	# Call the base function to start the drop
	super(msg)

func tween_jump() -> void:
	# Create a tween to track the progress of the jump arc
	var tween = get_tree().create_tween()
	await tween.tween_method(jump, 0.0, 1.0, jump_time).finished
	land()

func land() -> void:
	# Handle stunned landing
	if drop_height > stunnable_drop_height:
		print("Stunned landing.")
		enemy.animate.rpc(enemy.Animations.STUNNED)
		enemy.velocity = Vector3.ZERO
		
		var stun_time = drop_height * 0.1
		print("Stun time: " + str(stun_time))
		await get_tree().create_timer(stun_time).timeout
		transition.emit("RunEnemyState")
	# Handle regular landing
	else:
		print("Regular landing.")
		enemy.velocity = Vector3.ZERO
		transition.emit("RunEnemyState")
