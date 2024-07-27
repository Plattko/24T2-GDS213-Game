class_name JumpEnemyState
extends EnemyState

func enter(msg : Dictionary = {}) -> void:
	if msg.link_exit_position:
		enemy.global_position = msg.link_exit_position
	
	await get_tree().physics_frame
	transition.emit("RunEnemyState")
