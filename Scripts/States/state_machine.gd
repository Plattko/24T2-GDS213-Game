class_name StateMachine

extends Node

@export var initial_state : State

var states : Dictionary = {}
var current_state

func _ready():
	for child in get_children():
		if child is State:
			# Add a kvp of each state name and its state to the states dictionary
			states[child.name.to_lower()] = child
			# Connect each state to the transition signal
			child.transition.connect(on_child_transition)
		else:
			push_warning("State machine contains non-state child node.")
	
	# If there is an initial state call the state's enter and set it as the current state
	if initial_state:
		await owner.ready
		initial_state.enter(null)
		current_state = initial_state

func _unhandled_input(event):
	if current_state:
		current_state.handle_input(event)

func _process(delta):
	if current_state:
		current_state.update(delta)
	
	# Debug
	Global.debug.add_debug_property("Current State", current_state.name, 1)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(new_state_name):
	var new_state = states.get(new_state_name.to_lower())
	if new_state:
		if new_state != current_state:
			current_state.exit()
			new_state.enter(current_state)
			current_state = new_state
	else:
		push_warning("New state does not exist.")
