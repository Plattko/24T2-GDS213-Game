class_name PlayerInput

extends Node

var player : CharacterBody3D

var is_server : bool = false

# Input variables
var can_move : bool = true
var can_shoot : bool = true
var can_look : bool = true

func _ready() -> void:
	# Disable triggering input if it is the server in multiplayer
	if MultiplayerManager.is_multiplayer and get_multiplayer_authority() != multiplayer.get_unique_id():
		is_server = true

# --------------------------------MOVEMENT------------------------------------ #
var direction : Vector3:
	get:
		if not is_server and can_move:
			var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
			return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		return Vector3.ZERO

var is_move_forwards_pressed : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_pressed("move_forwards")
		return false

var is_jump_just_pressed : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_just_pressed("jump")
		return false

var is_sprint_pressed : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_pressed("sprint")
		return false

var is_sprint_just_released : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_just_released("sprint")
		return false

var is_crouch_pressed : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_pressed("crouch")
		return false

var is_crouch_just_released : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_just_released("crouch")
		return false

# --------------------------------SHOOTING------------------------------------ #
var is_shoot_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("shoot")
		return false

var is_shoot_just_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_just_pressed("shoot")
		return false

var is_reload_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("reload")
		return false

var is_weapon_1_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("weapon_1")
		return false

var is_weapon_2_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("weapon_2")
		return false

var is_weapon_3_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("weapon_3")
		return false

# --------------------------------TOGGLES------------------------------------ #
func on_opened_settings_menu() -> void:
	print("Disabled input.")
	can_move = false
	can_shoot = false
	can_look = false

func on_closed_settings_menu() -> void:
	print("Enabled input.")
	can_move = true
	can_shoot = true
	can_look = true
