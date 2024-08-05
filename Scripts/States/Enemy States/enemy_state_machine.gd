class_name EnemyStateMachine
extends StateMachine

func init(_enemy: CharacterBody3D) -> void:
	for child in get_children():
		if child is EnemyState:
			# Add a KVP of each state name and its state to the states dictionary
			states[child.name.to_lower()] = child
			# Connect each state to the transition signal
			child.transition.connect(on_child_transition)
			# Initialise child with its references
			child.init(_enemy)
		else:
			push_warning("State machine contains non-state child node.")
	
	# If there is an initial state call the state's enter and set it as the current state
	if initial_state:
		# Waiting one physics frame prevents an error when calling the animate RPC in the run state for the first time
		await get_tree().physics_frame
		initial_state.enter()
		current_state = initial_state

func _process(delta):
	if !multiplayer.is_server(): return
	super(delta)

func _physics_process(delta):
	if !multiplayer.is_server(): return
	super(delta)

func on_child_transition(new_state_name, msg : Dictionary = {}):
	var new_state = states.get(new_state_name.to_lower())
	if new_state:
		if new_state != current_state or new_state == states.get("AttackEnemyState".to_lower()):
			current_state.exit()
			new_state.enter(msg)
			current_state = new_state
	else:
		push_warning("New state does not exist.")

func _on_nav_agent_link_reached(details):
	if !multiplayer.is_server(): return
	#print("Link entry position: " + str(details.link_entry_position))
	# Call on_link_reached on the current state
	current_state.on_link_reached(details)
