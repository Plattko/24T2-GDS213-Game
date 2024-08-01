class_name State
extends Node

signal transition

func enter(_msg : Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta : float) -> void:
	pass

func physics_update(_delta : float) -> void:
	pass
