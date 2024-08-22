class_name ShakeableCamera
extends Area3D

var camera : Camera3D
var initial_rotation : Vector3

var trauma : float = 0.0
@export var trauma_reduction_rate : float = 1.0

@export var noise : FastNoiseLite
# Controls the speed at which the camera shakes
@export var noise_speed : float = 50.0

var elapsed_time : float = 0.0

# Determines the maximum angle in degrees the camera can rotate on the respective axis when shaking
var max_x : float = 10.0
var max_y : float = 10.0
var max_z : float = 5.0

func _ready() -> void:
	camera = get_parent()
	initial_rotation = camera.rotation_degrees

#func _unhandled_input(event):
	#if event is InputEventKey:
		#if event.pressed and event.keycode == KEY_B:
			#add_trauma(10.0)

func _process(delta) -> void:
	elapsed_time += delta
	# Ensure the trauma doesn't go below zero
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
	camera.rotation_degrees.x = initial_rotation.x + max_x * get_shake_intensity() * get_noise_from_seed(0)
	camera.rotation_degrees.y = initial_rotation.y + max_y * get_shake_intensity() * get_noise_from_seed(1)
	#camera.rotation_degrees.z = initial_rotation.z + max_z * get_shake_intensity() * get_noise_from_seed(2)

func add_trauma(trauma_amount: float) -> void:
	# Increase the trauma by the trauma amount while clamping it between 0 and 1
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	# Make the intensity of the screen shake scale by trauma squared for a more drastic increase
	return trauma * trauma

func get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(elapsed_time * noise_speed)
