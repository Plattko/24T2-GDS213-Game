class_name Damageable

extends Area3D

signal damaged (damage: float)

func take_damage (damage: float = 1):
	damaged.emit(damage)
