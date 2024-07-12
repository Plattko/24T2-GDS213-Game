class_name StateMachine

extends Node

var debug

var states : Dictionary = {}
@export var initial_state : State
var current_state : State

func initialise(player_ref: CharacterBody3D, input_ref: PlayerInput, debug_ref: Debug) -> void:
	for child in get_children():
		if child is State:
			debug = debug_ref
			# Add a KVP of each state name and its state to the states dictionary
			states[child.name.to_lower()] = child
			# Connect each state to the transition signal
			child.transition.connect(on_child_transition)
			# Initialise child with its references
			child.init(player_ref, input_ref, debug_ref)
		else:
			push_warning("State machine contains non-state child node.")
	
	# If there is an initial state call the state's enter and set it as the current state
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if current_state:
		current_state.handle_input(event)

func _process(delta):
	if not is_multiplayer_authority(): return
	
	if current_state:
		current_state.update(delta)
	# Debug
	if debug: debug.add_debug_property("Current State", current_state.name, 1)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
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
