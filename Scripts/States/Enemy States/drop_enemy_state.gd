class_name DropEnemyState
extends EnemyState

var stun_time_multiplier : float = 0.1

func enter(msg : Dictionary = {}) -> void:
	if !multiplayer.is_server(): return
	
	if msg.link_exit_position:
		enemy.global_position = msg.link_exit_position
	
	if msg.height and msg.height > stunnable_drop_height:
		print("Stunned landing.")
		enemy.animate(enemy.Animations.STUNNED)
		enemy.nav_agent.avoidance_enabled = false
		enemy.velocity = Vector3.ZERO
		
		var stun_time = msg.height * 0.1
		print("Stun time: " + str(stun_time))
		await get_tree().create_timer(stun_time).timeout
		enemy.nav_agent.avoidance_enabled = true
		transition.emit("RunEnemyState")
	else:
		print("Regular landing.")
		await get_tree().physics_frame
		enemy.velocity = Vector3.ZERO
		transition.emit("RunEnemyState")
