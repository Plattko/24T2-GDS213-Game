class_name MultiplayerPlayer
extends CharacterBody3D

@export var input : PlayerInput
@export var mesh : MeshInstance3D
@export var head : Node3D
@export var camera : Camera3D
@export var anim_player : AnimationPlayer
@export var ceiling_check : ShapeCast3D
@export var hud : HUD

@onready var state_machine : PlayerStateMachine = %PlayerStateMachine
@onready var weapon_manager : WeaponManager = %WeaponManager
@onready var reticle : Reticle = %Reticle
@onready var hitmarker : Hitmarker = %Hitmarker
@onready var debug : Debug = %DebugPanel

const CROUCH_ANIM : String = "Crouch"
const SLIDE_ANIM : String = "Slide"
const DOWNED_ANIM : String = "Downed"
const RESPAWN_ANIM : String = "Respawn"

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
@export var cur_health : float

# Knockback variables
var horizontal_knockback : Vector3 = Vector3.ZERO
var kb_reduction_rate : float = 20.0


# Temp(?) rocket jump variable
@export_group("Rocket Jump Variables")
@export var do_self_damage : bool = true

# Downed state
@export_group("Downed State Variables")
@export var is_downed : bool = false
@export var is_invincible : bool = false
@export var revive_health : float = 15.0
@export var revive_invincibility_sec : float = 1.0

@export_group("Death Variables")
@export var death_timer : Timer
@export var respawn_timer : Timer
var is_dead : bool = false
var is_vaporised : bool = false

signal update_health
signal player_downed
signal player_died(is_vaporised: bool)
signal player_revived
signal player_respawned

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	input.player = self
	state_machine.init(self, input, debug)
	weapon_manager.initialise(camera, input, reticle)
	#var shotgun = weapon_manager.find_child("Shotgun")
	#print(shotgun)
	#if shotgun: shotgun.player = self
	hud.init(death_timer, respawn_timer)
	
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
		if event.pressed and event.keycode == KEY_L:
			revive_player()

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
	
	# Down player if their health reaches 0
	if cur_health <= 0 and not is_downed and not is_dead:
		down_player()

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
	if is_on_wall() or state_machine.current_state == state_machine.states.get("SlidePlayerState".to_lower()) or is_downed:
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
			play_anim.rpc(CROUCH_ANIM, -anim_speed, true)
		elif current_state == "SlidePlayerState":
			play_anim.rpc(SLIDE_ANIM, -anim_speed, true)
		
		if anim_player.is_playing():
			await anim_player.animation_finished
	# If there is something blocking the way, try to uncrouch again in 0.1 seconds
	elif ceiling_check.is_colliding() == true and is_repeating_check:
		await get_tree().create_timer(0.1).timeout
		stand_up(current_state, anim_speed, true)

#-------------------------------------------------------------------------------
# Health
#-------------------------------------------------------------------------------
func on_damaged(damage: float, _is_crit: bool) -> void:
	if cur_health > 0.0 and !is_invincible:
		cur_health -= damage
		cur_health = clampf(cur_health, 0.0, max_health)
		update_health.emit([cur_health, max_health])
		print("Player health: " + str(cur_health))

func on_healed(health: float) -> void:
	if is_downed or is_dead: return
	cur_health += health
	cur_health = clampf(cur_health, 0.0, max_health)
	update_health.emit([cur_health, max_health])

func down_player() -> void:
	print("Player " + str(multiplayer.get_unique_id()) + " is downed.")
	is_downed = true
	is_invincible = true
	input.can_shoot = false
	death_timer.start()
	# Show the downed UI
	player_downed.emit()

@rpc("any_peer", "call_local")
func revive_player() -> void:
	# Only run if the player is downed
	if !is_downed: return
	# Notify the HUD
	player_revived.emit()
	# Stop the death timer
	death_timer.stop()
	# Set their health to the revive health
	cur_health = revive_health
	update_health.emit([cur_health, max_health])
	# Set is_downed to false so the next state doesn't transition to it immediately
	is_downed = false
	# Assuming they're in the downed state, call the revive_player function
	state_machine.current_state.revive_player()
	# Give them the ability to shoot after standing up
	if anim_player.current_animation == DOWNED_ANIM:
		print("In downed animation.")
		await anim_player.animation_finished
		print("Shooting restored.")
		input.can_shoot = true
		await get_tree().create_timer(revive_invincibility_sec).timeout
		is_invincible = false

func die(vaporised: bool):
	print("Player " + str(multiplayer.get_unique_id()) + " died.")
	if vaporised: respawn_timer.start()
	# Notify the HUD
	player_died.emit(vaporised)
	is_downed = false
	is_dead = true
	is_vaporised = vaporised
	# Reset knockback and velocity
	horizontal_knockback = Vector3.ZERO
	velocity = Vector3.ZERO
	# Hide mesh and disable collisions
	mesh.hide()
	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)
	# Hide the player's weapon
	weapon_manager.current_weapon.stop_anim.rpc()
	weapon_manager.current_weapon.mesh.visible = false
	# Disable moving and shooting
	input.can_move = false
	input.can_shoot = false

@rpc("any_peer", "call_local")
func respawn_player() -> void:
	# Notify the HUD
	player_respawned.emit()
	# Set their health to the max health
	cur_health = max_health
	update_health.emit([cur_health, max_health])
	# Set is_dead and is_vaporised to false
	is_dead = false
	is_vaporised = false
	is_invincible = false
	# Assuming they're in the downed state, call the respawn_player function
	state_machine.current_state.respawn_player()
	# Show mesh and enable collisions
	mesh.show()
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	# Set the player's position to the current respawn point
	global_position = GameManager.cur_respawn_point
	# Enable moving
	input.can_move = true
	# Reset to the player's first weapon
	weapon_manager.reset_weapon()
	# Enable shooting
	input.can_shoot = true

func _on_death_timer_timeout():
	die(false)

func _on_respawn_timer_timeout():
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
	sensitivity_setting.slider.value = sensitivity * 100
	var reload_type_setting = find_child("ReloadTypeSetting")
	reload_type_setting.reload_type_updated.connect(weapon_manager.set_reload_type)
	var do_side_tilt_setting = find_child("DoSideTiltSetting")
	do_side_tilt_setting.side_tilt_mode_updated.connect(set_side_tilt_mode)

#-------------------------------------------------------------------------------
# RPCs
#-------------------------------------------------------------------------------
@rpc("call_local")
func play_anim(anim: String, custom_speed: float = 1.0, from_end: bool = false) -> void:
	anim_player.play(anim, -1, custom_speed, from_end)

@rpc("call_local")
func seek_anim(anim: String, seconds: float) -> void:
	anim_player.current_animation = anim
	anim_player.seek(seconds, true)

@rpc("any_peer", "call_local")
func rocket_self_hit(damage: float, knockback: Vector3) -> void:
	# Apply the self-damage
	if do_self_damage: on_damaged(damage, false)
	# Apply the vertical explosion knockback to the player
	velocity.y += knockback.y
	# Apply the horizontal explosion knockback to the player
	var player_state : PlayerState = state_machine.current_state
	if player_state.name == "AirPlayerState":
		# If in the Air state, add it to the velocity directly
		player_state.is_air_strafing_enabled = true
		velocity.x += knockback.x * 1.3
		velocity.z += knockback.z * 1.3
	else:
		# Otherwise, update the horizontal knockback
		horizontal_knockback = knockback * 1.3
