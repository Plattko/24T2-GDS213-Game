class_name PlayerInput

extends Node

var player : CharacterBody3D

var is_server : bool = false

# Input variables
var can_move : bool = true
var can_shoot : bool = true
var can_look : bool = true

# Input buffer variables
@export_group("Input Buffer Variables")
@export var jump_buffer : Timer
@export var jump_buffer_cooldown : Timer

func _ready() -> void:
	## TODO: Make this work again
	## Disable triggering input if it is the server in multiplayer
	#if MultiplayerManager.is_multiplayer and get_multiplayer_authority() != multiplayer.get_unique_id():
		#is_server = true
	pass

#func _input(event):
	#if event.is_action_pressed("jump") and jump_buffer_cooldown.is_stopped():
		#jump_buffer.start()
		#jump_buffer_cooldown.start()

# --------------------------------MOVEMENT------------------------------------ #
var input_direction : Vector2:
	get:
		if not is_server and can_move:
			return Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
		return Vector2.ZERO

var direction : Vector3:
	get:
		if not is_server and can_move:
			return (player.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
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

var is_jump_pressed : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_pressed("jump")
		return false

var is_jump_just_released : bool:
	get:
		if not is_server and can_move:
			return Input.is_action_just_released("jump")
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

var weapon_scroll_direction : int:
	get:
		if not is_server and can_shoot:
			var up = -1 if Input.is_action_just_released("weapon_scroll_up") else 0
			var down = 1 if Input.is_action_just_released("weapon_scroll_down") else 0
			var scroll_dir = up + down
			return scroll_dir
		return 0

# ------------------------------INTERACTION---------------------------------- #
var is_interact_pressed : bool:
	get:
		if not is_server and can_shoot:
			return Input.is_action_pressed("interact")
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

# --------------------------------BUFFERS------------------------------------- #
#var is_jump_buffered : bool = false:
	#get:
		#return !jump_buffer.is_stopped()
