class_name PlayerState

extends State

var player : CharacterBody3D
var input : PlayerInput
var debug : Debug

const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 8.0

func init(player_ref: CharacterBody3D, input_ref: PlayerInput, debug_ref: Debug) -> void:
	player = player_ref
	input = input_ref
	debug = debug_ref
