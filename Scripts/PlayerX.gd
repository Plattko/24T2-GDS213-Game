extends CharacterBody3D

@export var head : Node3D
@export var camera : Camera3D
@export var animation_player : AnimationPlayer
@export var crouch_shape_cast : ShapeCast3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 8.0

# Camera movement variables
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3

var player_rotation : Vector3
var camera_rotation : Vector3

const MIN_CAMERA_TILT := deg_to_rad(-90)
const MAX_CAMERA_TILT := deg_to_rad(90)

const SENSITIVITY = 0.5

# Head bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Crouch variables
var is_crouching : bool = false

const CROUCH_SPEED : float = 7.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Handle quit
	if event.is_action_pressed("quit"):
		get_tree().quit()
	
	# Handle crouch
	if event.is_action_pressed("crouch") and is_on_floor() and !is_crouching:
		crouch(true)
	
	if event.is_action_released("crouch") and is_crouching:
		if crouch_shape_cast.is_colliding() == false:
			crouch(false)
		else:
			uncrouch_check()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_input = -event.relative.x * SENSITIVITY
		tilt_input = -event.relative.y * SENSITIVITY
		
		#head.rotate_y(-event.relative.x * SENSITIVITY)
		#camera.rotate_x(-event.relative.y * SENSITIVITY)
		#camera.rotation.x = clamp(camera.rotation.x, MIN_CAMERA_TILT, MAX_CAMERA_TILT)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle camera movement
	update_camera(delta)
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Handle sprint
	if Input.is_action_pressed("sprint") && !is_crouching:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle movement/deceleration
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = head_bob(t_bob)
	
	# FOV
	var velocity_clamped = clamp (velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func update_camera(delta):
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

func crouch(state : bool):
	match state:
		true:
			animation_player.play("Crouch", -1, CROUCH_SPEED)
		false:
			animation_player.play("Crouch", -1, -CROUCH_SPEED, true)

func uncrouch_check():
	if crouch_shape_cast.is_colliding() == false:
		crouch(false)
	else:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func _on_animation_player_animation_started(anim_name):
	if anim_name == "Crouch":
		is_crouching = !is_crouching
