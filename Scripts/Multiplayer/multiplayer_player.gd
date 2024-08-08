class_name MultiplayerPlayer
extends CharacterBody3D

@export var input : PlayerInput
@export var head : Node3D
@export var camera : Camera3D
@export var animation_player : AnimationPlayer
@export var ceiling_check : ShapeCast3D
@export var player_audio : Node

@onready var state_machine : PlayerStateMachine = %PlayerStateMachine
@onready var weapon_manager : WeaponManager = %WeaponManager
@onready var reticle : Reticle = %Reticle
@onready var hitmarker : Hitmarker = %Hitmarker
@onready var debug : Debug = %DebugPanel

# Camera movement variables
@export_group("Camera Movement Variables")
const MIN_CAMERA_TILT := deg_to_rad(-90)
const MAX_CAMERA_TILT := deg_to_rad(90)

@export_range(0.1, 0.25, 0.01) var sensitivity := 0.25

const head_tilt_amount := deg_to_rad(3)
var weapon_tilt_amount := deg_to_rad(5)
var side_tilt_speed := 5.0
enum Side_Tilt_Modes { DEFAULT, GROUND_ONLY, NEVER}
var side_tilt_mode := Side_Tilt_Modes.DEFAULT

@export var weapon_holder : Node3D
var weapon_sway_amount := deg_to_rad(0.25) / 6
var mouse_input : Vector2

# Bob variables
var can_bob : bool = true
var t_bob := 0.0
var bob_freq := 2.0
var bob_amp := 0.08

var wpn_bob_freq := 0.012
#var wpn_bob_amp := 0.32
var wpn_bob_amp := 0.15
var wpn_return_speed := 2.0

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

# Temp(?) rocket jump variable
@export_group("Rocket Jump Variables")
@export var do_self_damage : bool = true

signal update_health

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	input.player = self
	state_machine.init(self, input, debug)
	weapon_manager.initialise(camera, input, reticle)
	var shotgun = weapon_manager.find_child("Shotgun")
	print(shotgun)
	if shotgun: shotgun.player = self
	
	handle_connected_signals()
	
	cur_health = max_health
	update_health.emit([cur_health, max_health])

func _input(event) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion and input.can_look:
		var mouse_delta = event.relative * sensitivity * 0.01
		head.rotation.x -= mouse_delta.y
		head.rotation.x = clamp(head.rotation.x, MIN_CAMERA_TILT, MAX_CAMERA_TILT)
		rotation.y -= mouse_delta.x
		mouse_input = event.relative

func _unhandled_input(event) -> void:
	if not is_multiplayer_authority(): return
	
	# Health debug
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			on_damaged(20, false)
		if event.pressed and event.keycode == KEY_O:
			on_healed(20)
		if event.pressed and event.keycode == KEY_I:
			do_self_damage = !do_self_damage

func _physics_process(delta) -> void:
	if not is_multiplayer_authority(): return
	
	# Handle weapon and head bob
	head_bob(delta)
	weapon_bob(delta)
	# Handle side tilt
	cam_side_tilt(delta)
	weapon_sway(delta)
	# Handle FOV
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
		debug.add_debug_property("Air Strafing", state_machine.states.get("AirPlayerState".to_lower()).is_air_strafing_enabled, 4)
	
	# Respawn player if their health reaches 0
	if cur_health <= 0 and not is_dead:
		respawn_player()

#-------------------------------------------------------------------------------
# Camera
#-------------------------------------------------------------------------------
func head_bob(delta: float) -> void:
	if can_bob:
		t_bob += delta * velocity.length()
		var bob_pos = Vector3.ZERO
		bob_pos.y = sin(t_bob * bob_freq) * bob_amp
		bob_pos.x = cos(t_bob * bob_freq / 2) * bob_amp
		camera.transform.origin = bob_pos

func weapon_bob(delta: float) -> void: # TODO: Fix head bob and weapon bob being out of sync
	var vel = velocity.length()
	if can_bob and vel > 0.01:
		var bob_pos = Vector3.ZERO
		var speed_modifier = vel / PlayerState.WALK_SPEED
		var time = Time.get_ticks_msec() * speed_modifier
		var weight = delta * speed_modifier
		bob_pos.y = sin(time * wpn_bob_freq) * wpn_bob_amp
		bob_pos.x = sin(time * wpn_bob_freq / 2) * wpn_bob_amp
		weapon_holder.position = lerp(weapon_holder.position, bob_pos, weight)
	else:
		var def_pos = Vector3.ZERO
		var weight = wpn_return_speed * delta
		weapon_holder.position = lerp(weapon_holder.position, def_pos, weight)

func weapon_sway(delta: float) -> void:
	mouse_input = lerp(mouse_input, Vector2.ZERO, delta * 10)
	weapon_holder.rotation.x = lerp(weapon_holder.rotation.x, mouse_input.y * weapon_sway_amount, delta * 15)
	weapon_holder.rotation.y = lerp(weapon_holder.rotation.y, mouse_input.x * weapon_sway_amount, delta * 15)

func cam_side_tilt(_delta: float) -> void:
	if side_tilt_mode == Side_Tilt_Modes.NEVER: return
	if is_on_wall() or state_machine.current_state == state_machine.states.get("SlidePlayerState".to_lower()):
		tilt(head, 0.0, _delta)
		tilt(weapon_holder, 0.0, _delta)
	elif is_on_floor() or side_tilt_mode == Side_Tilt_Modes.DEFAULT:
		var input_x = input.input_direction.x
		tilt(head, -input_x * head_tilt_amount, _delta)
		tilt(weapon_holder, -input_x * weapon_tilt_amount, _delta)
	else:
		tilt(head, 0.0, _delta)
		tilt(weapon_holder, 0.0, _delta)

func tilt(node: Node3D, target_tilt: float, delta: float) -> void:
	node.rotation.z = lerp(node.rotation.z, target_tilt, delta * side_tilt_speed)

func set_sensitivity(value: float) -> void:
	sensitivity = value
	print("Player sensitivity: %s" % sensitivity)

func set_side_tilt_mode(mode: Side_Tilt_Modes):
	side_tilt_mode = mode
	if (mode == Side_Tilt_Modes.GROUND_ONLY and !is_on_floor()) or mode == Side_Tilt_Modes.NEVER:
		head.rotation.z = 0

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

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
func on_damaged(damage: float, _is_crit: bool) -> void:
	if cur_health > 0.0:
		cur_health -= damage
		cur_health = clampf(cur_health, 0.0, max_health)
		update_health.emit([cur_health, max_health])
		print("Player health: " + str(cur_health))

func on_healed(health: float) -> void:
	cur_health += health
	cur_health = clampf(cur_health, 0.0, max_health)
	update_health.emit([cur_health, max_health])

func respawn_player() -> void:
	is_dead = true
	horizontal_knockback = Vector3.ZERO
	velocity = Vector3.ZERO
	global_position = GameManager.cur_respawn_point
	print("Current respawn position: " + str(GameManager.cur_respawn_point))
	print("Player position after respawning: " + str(global_position))
	cur_health = max_health
	update_health.emit([cur_health, max_health])
	is_dead = false

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
			weapon.regular_hit.connect(player_audio.PlayNormalHitmarker)
			weapon.crit_hit.connect(hitmarker.on_crit_hit)
			weapon.crit_hit.connect(player_audio.PlayHeadshotHitmarker)
	
	var sensitivity_setting = find_child("SensitivitySliderSetting")
	sensitivity_setting.sensitivity_updated.connect(set_sensitivity)
	sensitivity_setting.slider.value = sensitivity * 100
	var reload_type_setting = find_child("ReloadTypeSetting")
	reload_type_setting.reload_type_updated.connect(weapon_manager.set_reload_type)
	var do_side_tilt_setting = find_child("DoSideTiltSetting")
	do_side_tilt_setting.side_tilt_mode_updated.connect(set_side_tilt_mode)
