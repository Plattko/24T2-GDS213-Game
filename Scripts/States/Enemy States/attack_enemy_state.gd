class_name AttackEnemyState
extends EnemyState

func enter(_msg : Dictionary = {}) -> void:
	# Only run by the server
	if !multiplayer.is_server(): return
	#Play the attack animation
	enemy.animate.rpc(enemy.Animations.ATTACK)
	# Set the enemy's velocity to 0
	enemy.nav_agent.set_velocity(Vector3.ZERO)
	# Transition when the animation is finished
	await enemy.anim_tree.animation_finished
	on_attack_animation_finished()

func physics_update(delta : float) -> void:
	# Make enemy look at player
	var player_dir = enemy.player.global_position - enemy.global_position
	rotate_towards(player_dir, delta)

func on_attack_animation_finished() -> void:
	if enemy.target_in_range():
		transition.emit("AttackEnemyState")
	else:
		transition.emit("RunEnemyState")
