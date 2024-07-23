class_name Damageable

extends Area3D

@export var is_weak_point : bool = false

signal damaged (damage: float, is_crit: bool)

@rpc("any_peer", "call_local")
func take_damage (damage: float, is_crit: bool):
	damaged.emit(damage, is_crit)
