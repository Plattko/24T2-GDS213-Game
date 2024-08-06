class_name PlayerState

extends State

var player : MultiplayerPlayer
var input : PlayerInput
var debug : Debug

var horizontal_velocity : Vector2:
	get:
		return Vector2(player.velocity.x, player.velocity.z)

const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 8.0
const DOWNED_SPEED : float = 2.0

func init(_player: CharacterBody3D, _input: PlayerInput, _debug: Debug) -> void:
	player = _player
	input = _input
	debug = _debug

func set_velocity(direction: Vector3, speed: float) -> Vector3:
	var velocity : Vector3 = Vector3.ZERO
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	return velocity

## TODO: Split into x and z axes
#func lerp_velocity(from: Vector3, to: Vector3, rate: float) -> Vector3: # NOTE: Add delta in rate parameter
	#var velocity : Vector3 = Vector3.ZERO
	#velocity.x = lerp(from.x, to.x, rate)
	#velocity.z = lerp(from.z, to.z, rate)
	#return velocity
