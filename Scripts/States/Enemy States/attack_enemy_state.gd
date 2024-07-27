class_name AttackEnemyState
extends EnemyState

func enter(_msg : Dictionary = {}) -> void:
	if multiplayer.is_server():
		enemy.animate(enemy.Animations.ATTACK)
		enemy.nav_agent.set_velocity(Vector3.ZERO)
	else:
		enemy.animate(enemy.cur_anim)
	
	await enemy.anim_tree.animation_finished
	on_attack_animation_finished()

func physics_update(_delta : float) -> void:
	# Make enemy look at player
	enemy.look_at(Vector3(enemy.player.global_position.x, enemy.global_position.y, enemy.player.global_position.z), Vector3.UP)

func on_attack_animation_finished() -> void:
	if enemy.target_in_range():
		transition.emit("AttackEnemyState")
	else:
		transition.emit("RunEnemyState")
