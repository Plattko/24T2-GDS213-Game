class_name EnemySpawnBeam
extends Node3D

@export var anim_player : AnimationPlayer
@export var beam_inner_body : GPUParticles3D

func _ready() -> void:
	if !multiplayer.is_server(): return
	beam_inner_body.finished.connect(on_beam_inner_body_finished)

@rpc("call_local")
func play() -> void:
	print("Played enemy spawn beam strike animation")
	anim_player.play("Strike")

func on_beam_inner_body_finished() -> void:
	queue_free()
