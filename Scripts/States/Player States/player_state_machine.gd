class_name PlayerStateMachine
extends StateMachine

var debug : Debug

func init(_player: CharacterBody3D, _input: PlayerInput = null, _debug: Debug = null) -> void:
	debug = _debug
	
	for child in get_children():
		if child is PlayerState:
			# Add a KVP of each state name and its state to the states dictionary
			states[child.name.to_lower()] = child
			# Connect each state to the transition signal
			child.transition.connect(on_child_transition)
			# Initialise child with its references
			child.init(_player, _input, _debug)
		else:
			push_warning("State machine contains non-state child node.")
	
	# If there is an initial state call the state's enter and set it as the current state
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta):
	if not is_multiplayer_authority(): return
	super(delta)
	# Debug
	if debug: debug.add_debug_property("Current State", current_state.name, 1)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	super(delta)
