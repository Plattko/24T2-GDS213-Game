class_name StateMachine
extends Node

var states : Dictionary = {}
@export var initial_state : State
var current_state : State

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(new_state_name, msg : Dictionary = {}):
	var new_state = states.get(new_state_name.to_lower())
	if new_state:
		if new_state != current_state:
			current_state.exit()
			new_state.enter(msg)
			current_state = new_state
	else:
		push_warning("New state does not exist.")
