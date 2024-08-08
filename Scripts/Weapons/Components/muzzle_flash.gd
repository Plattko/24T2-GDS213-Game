class_name MuzzleFlash

extends Node3D

@export var light : OmniLight3D
@export var emitter : GPUParticles3D

var third_person_material = load("res://Assets/Materials/Shader Materials/muzzle_flash_third_person_shader.tres")

@export var flash_time := 0.05

func _ready():
	if !is_multiplayer_authority():
		# Set the muzzle flash to the muzzle flash third person material
		emitter.material_override = third_person_material

@rpc("call_local")
func add_muzzle_flash() -> void:
	light.visible = true
	emitter.restart()
	await get_tree().create_timer(flash_time).timeout
	light.visible = false
