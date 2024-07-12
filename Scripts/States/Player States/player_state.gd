class_name PlayerState

extends State

var player : CharacterBody3D
var input : PlayerInput
var debug : Debug

var horizontal_velocity : Vector2:
	get:
		return Vector2(player.velocity.x, player.velocity.z)

const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 8.0

func init(player_ref: CharacterBody3D, input_ref: PlayerInput, debug_ref: Debug) -> void:
	player = player_ref
	input = input_ref
	debug = debug_ref

func set_velocity(speed: float) -> Vector3:
	var velocity : Vector3 = Vector3.ZERO
	velocity.x = input.direction.x * speed
	velocity.z = input.direction.z * speed
	return velocity

## TODO: Split into x and z axes
func lerp_velocity(from: Vector3, to: Vector3, rate: float) -> Vector3: # NOTE: Add delta in rate parameter
	var velocity : Vector3 = Vector3.ZERO
	velocity.x = lerp(from.x, to.x, rate)
	velocity.z = lerp(from.z, to.z, rate)
	return velocity
