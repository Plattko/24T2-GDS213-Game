class_name EnemyState
extends State

var enemy : Enemy

# Navigation link variables
var max_jump_height : float = 5.0
var max_drop_height : float = 8.0
var stunnable_drop_height : float = 4.0

func init(_enemy: CharacterBody3D) -> void:
	enemy = _enemy

func on_link_reached(_details : Dictionary) -> void:
	pass
