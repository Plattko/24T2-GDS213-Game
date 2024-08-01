class_name EnemyState
extends State

var enemy : Enemy

@export_group("Turning Variables")
@export var rotation_speed : float = 12.0

# Navigation link variables
var max_jump_height : float = 5.0
var max_drop_height : float = 8.0
var stunnable_drop_height : float = 4.0

func init(_enemy: CharacterBody3D) -> void:
	enemy = _enemy

func on_link_reached(_details : Dictionary) -> void:
	pass

func rotate_towards(target: Vector3, delta: float):
	var look_dir = Vector3(-enemy.transform.basis.z.x, 0.0, -enemy.transform.basis.z.z)
	target.y = 0.0
	var angle_to = signed_angle_to(look_dir, target, Vector3.UP)
	enemy.rotate(Vector3.UP, fmod(delta * rotation_speed * angle_to, PI))

func signed_angle_to(from: Vector3, to: Vector3, axis: Vector3) -> float:
	var dot_p = from.dot(to)
	var dir = from.cross(to).dot(axis)

	var unsigned = acos(dot_p / from.length() / to.length())
	if dir > 0:
		return unsigned
	else:
		return -unsigned
