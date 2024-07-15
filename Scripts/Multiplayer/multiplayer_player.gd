class_name MultiplayerPlayer
extends CharacterBody3D

@export var input : PlayerInput
@export var head : Node3D
@export var camera : Camera3D
@export var animation_player : AnimationPlayer
@export var ceiling_check : ShapeCast3D

#@onready var input = %Input
@onready var state_machine = %PlayerStateMachine
@onready var weapon_manager = %WeaponManager
@onready var reticle = %Reticle
@onready var hitmarker = %Hitmarker
@onready var debug = %DebugPanel

# Camera movement variables
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3

var player_rotation : Vector3
var camera_rotation : Vector3

const MIN_CAMERA_TILT := deg_to_rad(-90)
const MAX_CAMERA_TILT := deg_to_rad(90)

var sensitivity := 0.25

# Head bob variables
const BOB_FREQ := 2.0
const BOB_AMP := 0.08
var t_bob := 0.0

var can_head_bob : bool = true

# FOV variables
const BASE_FOV := 90.0
const FOV_CHANGE := 1.5
const FOV_VELOCITY_CLAMP := 8.0

# Health variables
var max_health := 100
var cur_health
var is_dead : bool = false

# Knockback variables
var horizontal_knockback : Vector3 = Vector3.ZERO
var kb_reduction_rate : float = 20.0

signal update_health

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	input.player = self
	state_machine.initialise(self, input, debug)
	weapon_manager.initialise(camera, input, reticle)
	
	handle_connected_signals()
	
	cur_health = max_health
	update_health.emit([cur_health, max_health])

func _unhandled_input(event) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and input.can_look: # TODO Move check to PlayerInput if possible
		rotation_input = -event.relative.x * sensitivity
		tilt_input = -event.relative.y * sensitivity
	
	# Health debug
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			on_damaged(20)

func _process(delta) -> void:
	if not is_multiplayer_authority(): return
	
	# Handle camera movement
	update_camera(delta)

func _physics_process(delta) -> void:
	if not is_multiplayer_authority(): return
	
	# Head bob
	if can_head_bob:
		t_bob += delta * velocity.length()
		camera.transform.origin = head_bob(t_bob)
	
	# FOV
	var velocity_clamped = clamp (velocity.length(), 0.5, FOV_VELOCITY_CLAMP * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Update knockback
	if abs(horizontal_knockback.length()) > 0.0:
		update_knockback(delta)
	
	# Debug
	if debug:
		debug.add_debug_property("Move Speed", snappedf(Vector2(velocity.x, velocity.z).length(), 0.01), 2)
		debug.add_debug_property("Vertical Speed", snappedf(velocity.y, 0.01), 3)
		#debug.add_debug_property("Jump Buffer", snappedf(input.jump_buffer.time_left, 0.01), 3)
		#debug.add_debug_property("Jump Buffer Cooldown", snappedf(input.jump_buffer_cooldown.time_left, 0.01), 4)
	
	if cur_health <= 0 and not is_dead:
		respawn_player()

#-------------------------------------------------------------------------------
# Initialisation
#-------------------------------------------------------------------------------
func handle_connected_signals() -> void:
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)
	
	for weapon in weapon_manager.get_children():
		if weapon is Weapon:
			# Connect the hitmarker to each weapon's regular and crit hit signals
			weapon.regular_hit.connect(hitmarker.on_regular_hit)
			weapon.crit_hit.connect(hitmarker.on_crit_hit)
	
	var sensitivity_setting = find_child("SensitivitySliderSetting")
	sensitivity_setting.sensitivity_updated.connect(set_sensitivity)
	var reload_type_setting = find_child("ReloadTypeSetting")
	reload_type_setting.reload_type_updated.connect(weapon_manager.set_reload_type)

#-------------------------------------------------------------------------------
# Camera
#-------------------------------------------------------------------------------
func update_camera(delta) -> void:
	mouse_rotation.y += rotation_input * delta
	mouse_rotation.x += tilt_input * delta
	mouse_rotation.x = clamp(mouse_rotation.x, MIN_CAMERA_TILT, MAX_CAMERA_TILT)
	
	player_rotation = Vector3(0.0, mouse_rotation.y, 0.0)
	camera_rotation = Vector3(mouse_rotation.x, 0.0, 0.0)
	
	global_transform.basis = Basis.from_euler(player_rotation)
	head.transform.basis = Basis.from_euler(camera_rotation)
	head.rotation.z = 0.0
	
	rotation_input = 0.0
	tilt_input = 0.0

func head_bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func set_sensitivity(value: float) -> void:
	sensitivity = value
	print("Player sensitivity: %s" % sensitivity)

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
func on_damaged(damage: float) -> void:
	if cur_health > 0.0:
		cur_health -= damage
		update_health.emit([cur_health, max_health])
		print("Player health: " + str(cur_health))

func respawn_player() -> void:
	is_dead = true
	global_position = GameManager.cur_respawn_point
	print("Current respawn position: " + str(GameManager.cur_respawn_point))
	print("Player position after respawning: " + str(global_position))
	cur_health = max_health
	update_health.emit([cur_health, max_health])
	is_dead = false

#-------------------------------------------------------------------------------
# Movement
#-------------------------------------------------------------------------------
func update_gravity(delta) -> void:
	#velocity.y -= gravity * delta
	velocity.y -= 18 * delta

func update_velocity(vel: Vector3) -> void: # TODO: Make function work with multiple occuring knockbacks
	var new_velocity : Vector3 = vel + horizontal_knockback
	#print("New velocity: " + str(new_velocity.length()))
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	move_and_slide()

func update_knockback(delta: float) -> void:
	if abs(horizontal_knockback.length()) > 0.01:
		horizontal_knockback = horizontal_knockback.move_toward(Vector3.ZERO, kb_reduction_rate * delta)
	else:
		horizontal_knockback = Vector3.ZERO
	#print("Knockback: " + str(horizontal_knockback.length()))

func stand_up(current_state, anim_speed : float, is_repeating_check : bool) -> void:
	# If there is nothing blocking the player from standing up, play the respective animation
	if ceiling_check.is_colliding() == false:
		# Check if it is the crouch or slide animation
		if current_state == "CrouchPlayerState":
			animation_player.play("Crouch", -1, -anim_speed, true)
		elif current_state == "SlidePlayerState":
			animation_player.play("Slide", -1, -anim_speed, true)
		
		if animation_player.is_playing():
			await animation_player.animation_finished
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif ceiling_check.is_colliding() == true and is_repeating_check:
		await get_tree().create_timer(0.1).timeout
		stand_up(current_state, anim_speed, true)
