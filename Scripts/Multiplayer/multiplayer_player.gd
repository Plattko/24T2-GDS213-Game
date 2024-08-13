class_name MultiplayerPlayer
extends CharacterBody3D

@export var input : PlayerInput
@export var mesh : MeshInstance3D
@export var head : Node3D
@export var camera : Camera3D
@export var anim_player : AnimationPlayer
@export var ceiling_check : ShapeCast3D
@export var player_audio : Node
@export var ui : UIManager
@export var hud : HUD

@onready var state_machine : PlayerStateMachine = %PlayerStateMachine
@onready var weapon_manager : WeaponManager = %WeaponManager
@onready var reticle : Reticle = %Reticle
@onready var hitmarker : Hitmarker = %Hitmarker
@onready var debug : Debug = %DebugPanel

var third_person_material = load("res://Assets/Materials/Standard Materials/player_third_person_material.tres")

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

@export_group("Interaction Variables")
@export var interact_raycast : RayCast3D
@export var revive_other_timer : Timer
var revive_target : MultiplayerPlayer
var revive_target_id : int

var primary_weapon : String
var secondary_weapon : String

signal update_health
signal player_downed
signal player_died(is_vaporised: bool)
signal player_revived
signal player_respawned
signal interactable_focused(interact_text: String, interact_key: String)
signal interactable_unfocused
signal revive_started
signal revive_stopped

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): 
		# Set player's mesh to the third person material if not the client's player
		mesh.set_surface_override_material(0, third_person_material)
		return
	
	# Hide the cursor and capture it at the centre of the screen
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Set the camera as current if we are this player
	camera.current = true
	
	input.player = self
	state_machine.init(self, input, debug)
	weapon_manager.initialise(camera, input, reticle)
	#var shotgun = weapon_manager.find_child("Shotgun")
	#print(shotgun)
	#if shotgun: shotgun.player = self
	hud.init(death_timer, respawn_timer, revive_other_timer)
	
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
	
	if input.is_interact_just_released and revive_target:
		stop_revive()

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
		if event.pressed and event.keycode == KEY_K:
			respawn_player()

func _physics_process(delta) -> void:
	if not is_multiplayer_authority(): return
	
	interact_cast()
	
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
	# Disable shooting
	input.can_shoot = false
	# Start the death timer
	death_timer.start()
	# Notify the HUD
	player_downed.emit()

@rpc("any_peer", "call_local")
func pause_death_timer() -> void:
	death_timer.paused = true

@rpc("any_peer", "call_local")
func resume_death_timer() -> void:
	death_timer.paused = false

@rpc("any_peer", "call_local")
func die(_is_vaporised: bool):
	print("Player " + str(multiplayer.get_unique_id()) + " died.")
	if is_dead: return
	if is_downed:
		is_downed = false
		death_timer.stop()
	is_invincible = true
	is_dead = true
	is_vaporised = _is_vaporised
	# Disable moving and shooting
	input.can_move = false
	input.can_shoot = false
	# If the player was vaporised, start the respawn timer
	if is_vaporised: respawn_timer.start()
	# Notify the HUD
	player_died.emit(is_vaporised)
	# Reset knockback and velocity
	horizontal_knockback = Vector3.ZERO
	velocity = Vector3.ZERO
	# Hide mesh
	mesh.hide()
	# Disable collisions except for the environment
	set_collision_layer_value(2, false)
	set_collision_mask_value(3, false)
	# Hide the player's weapon
	weapon_manager.current_weapon.stop_anim.rpc()
	weapon_manager.current_weapon.mesh.visible = false
	# Notify the Wave Manager
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	wave_manager.on_player_died.rpc_id(1)

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
	# Assuming they're in the downed state, transition to the idle or crouch state
	state_machine.current_state.revive_player()
	# Give them the ability to shoot after standing up
	if anim_player.current_animation == DOWNED_ANIM:
		await anim_player.animation_finished
		input.can_shoot = true
	else:
		input.can_shoot = true
	# Disable invincibility after the revive invincibility duration ends
	await get_tree().create_timer(revive_invincibility_sec).timeout
	is_invincible = false

func respawn_player() -> void:
	# Only run if the player is dead
	if !is_dead: return
	# Notify the HUD
	player_respawned.emit()
	# Set their health to the max health
	cur_health = max_health
	update_health.emit([cur_health, max_health])
	# Set is_dead and is_vaporised to false
	is_dead = false
	is_vaporised = false
	is_invincible = false
	# Assuming they're in the downed state, transition to the idle state
	state_machine.current_state.respawn_player()
	# Show mesh and enable collisions
	mesh.show()
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	# Set the player's position to the current respawn point
	var scene_manager = get_tree().get_first_node_in_group("level")
	global_position = scene_manager.cur_respawn_point
	# Enable moving
	input.can_move = true
	# Reset to the player's first weapon
	weapon_manager.reset_weapon()
	# Enable shooting
	input.can_shoot = true
	# Notify the Wave Manager
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	wave_manager.on_player_respawned.rpc_id(1)

func _on_death_timer_timeout() -> void:
	die(false)

func _on_respawn_timer_timeout() -> void:
	respawn_player()

func on_intermission_entered() -> void:
	if is_downed:
		revive_player()
	elif is_dead and not is_vaporised:
		respawn_player()

func on_game_over() -> void:
	# Set the player's camera to the map camera
	var map_camera = get_tree().get_first_node_in_group("map_camera") as Camera3D
	map_camera.current = true
	# Blur the background
	ui.show_blur()
	# Prevent the players from respawning
	respawn_timer.stop()

#-------------------------------------------------------------------------------
# Interaction
#-------------------------------------------------------------------------------
func interact_cast() -> void:
	if interact_raycast.is_colliding() and input.can_shoot:
		var focused = interact_raycast.get_collider()
		# Handle interaction with downed players
		if focused is MultiplayerPlayer and focused.is_downed:
			var interact_text = "Revive"
			# TODO: Replace with actively getting interact key
			var interact_key = "F"
			# Notify the HUD
			interactable_focused.emit(interact_text, interact_key)
			# If the player presses the interact button, start the revive
			if input.is_interact_just_pressed:
				revive_target = focused
				revive_target_id = focused.name.to_int()
				start_revive()
		else:
			# Notify the HUD
			interactable_unfocused.emit()
			# If there is an ongoing revive, stop it
			if revive_target: stop_revive()
	else:
		# Notify the HUD
		interactable_unfocused.emit()
		# If there is an ongoing revive, stop it
		if revive_target: stop_revive()

func start_revive() -> void:
	print("Started revive.")
	revive_target.pause_death_timer.rpc_id(revive_target_id)
	revive_started.emit()
	revive_other_timer.start()

func stop_revive() -> void:
	print("Stopped revive.")
	revive_target.resume_death_timer.rpc_id(revive_target_id)
	revive_stopped.emit()
	revive_target = null
	revive_target_id = 0
	revive_other_timer.stop()

func _on_revive_other_timer_timeout() -> void:
	print("Revived player: " + str(revive_target_id))
	# Revive the target player
	revive_target.revive_player.rpc_id(revive_target_id)

#-------------------------------------------------------------------------------
# Initialisation
#-------------------------------------------------------------------------------
func handle_connected_signals() -> void:
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	wave_manager.intermission_entered.connect(on_intermission_entered)
	wave_manager.game_over_entered.connect(on_game_over)
	
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
	
	# Connect signals to HUD
	update_health.connect(hud.on_update_health)
	player_downed.connect(hud.on_player_downed)
	player_died.connect(hud.on_player_died)
	player_revived.connect(hud.on_player_revived)
	player_respawned.connect(hud.on_player_respawned)
	interactable_focused.connect(hud.on_interactable_focused)
	interactable_unfocused.connect(hud.on_interactable_unfocused)
	revive_started.connect(hud.on_revive_started)
	revive_stopped.connect(hud.on_revive_stopped)
	
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
