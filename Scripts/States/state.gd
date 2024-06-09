class_name State

extends Node

signal transition

func enter(previous_state, msg : Dictionary = {}):
	pass

func exit():
	pass

func handle_input(event : InputEvent):
	pass

func update(delta : float):
	pass

func physics_update(delta : float):
	pass
