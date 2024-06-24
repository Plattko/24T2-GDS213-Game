extends CharacterBody3D

@onready var input = %Input
@onready var state_machine = %PlayerStateMachine
@onready var weapon_manager = %WeaponManager
@onready var reticle = %Reticle

func _ready() -> void:
	input.player = self
	state_machine.initialise(self, input)
	weapon_manager.initialise(input, reticle)

@export var player_id := 1: # An ID of 1 for any peer represents the server
	set(id):
		player_id = id
