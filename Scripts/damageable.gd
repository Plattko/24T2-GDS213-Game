class_name Damageable

extends Area3D

@export var is_weak_point : bool = false

signal damaged (damage: float)

@rpc("any_peer", "call_local")
func take_damage (damage: float = 1):
	damaged.emit(damage)
