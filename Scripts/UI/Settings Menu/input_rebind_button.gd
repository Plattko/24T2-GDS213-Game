class_name InputRebindButton
extends Control

@export var label : Label
@export var button : Button
@export var action_name : String

var input_interceptor : InputInterceptor

func _ready() -> void:
	input_interceptor = get_tree().get_first_node_in_group("input_interceptor")
	button.toggled.connect(on_button_toggled)
	# Prevent always being able to rebind keys
	set_process_unhandled_input(false)
	set_input_label()
	set_button_key_text()

func _unhandled_input(event) -> void:
	rebind_input_action(event)

func on_button_toggled(toggled_on: bool) -> void:
	# Set the button's processing of unhandled input based on whether or not it is pressed
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		button.text = "Press Any Button"
		input_interceptor.activate(self)
	else:
		set_button_key_text()
		input_interceptor.deactivate()

func rebind_input_action(event: InputEvent) -> void:
	var input_to_remove = InputMap.action_get_events(action_name)[0]
	InputMap.action_erase_event(action_name, input_to_remove)
	InputMap.action_add_event(action_name, event)
	# When we press a key, untoggle the button
	button.button_pressed = false

func set_button_key_text() -> void:
	var action_event = InputMap.action_get_events(action_name)[0]
	var action_input_text = action_event.as_text().trim_suffix(" (Physical)")
	button.text = str(action_input_text)

func set_input_label() -> void:
	label.text = "Unassigned"
	
	match action_name:
		"move_forwards":
			label.text = "Forward"
		"move_backwards":
			label.text = "Back"
		"move_left":
			label.text = "Left"
		"move_right":
			label.text = "Right"
		"jump":
			label.text = "Jump"
		"crouch":
			label.text = "Crouch/Slide"
		"shoot":
			label.text = "Shoot"
		"reload":
			label.text = "Reload"
		"weapon_1":
			label.text = "Weapon 1"
		"weapon_2":
			label.text = "Weapon 2"
		"weapon_scroll_up":
			label.text = "Previous Weapon"
		"weapon_scroll_down":
			label.text = "Next Weapon"
		"interact":
			label.text = "Interact"
		"escape":
			label.text = "Escape Menu/Back"

