extends Node3D

@export var sparks : GPUParticles3D
@export var flare : GPUParticles3D

var counter : int = 0

func _ready() -> void:
	sparks.emitting = true
	flare.emitting = true

func _on_sparks_finished():
	counter += 1
	if counter == 2: queue_free()

func _on_flare_finished():
	counter += 1
	if counter == 2: queue_free()
