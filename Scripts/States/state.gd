class_name State

extends Node

signal transition

func enter(_previous_state, _msg : Dictionary = {}):
	pass

func exit():
	pass

func handle_input(_event : InputEvent):
	pass

func update(_delta : float):
	pass

func physics_update(_delta : float):
	pass
