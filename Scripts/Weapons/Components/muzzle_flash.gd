class_name MuzzleFlash

extends Node3D

@export var light : OmniLight3D
@export var emitter : GPUParticles3D

@export var flash_time := 0.05

func _ready():
	pass

@rpc("call_local")
func add_muzzle_flash() -> void:
	light.visible = true
	emitter.emitting = true
	await get_tree().create_timer(flash_time).timeout
	light.visible = false
