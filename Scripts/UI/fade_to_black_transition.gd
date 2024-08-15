class_name FadeToBlackTransition
extends Control

@export var anim_player : AnimationPlayer

@rpc("call_local")
func play() -> void:
	anim_player.play("FadeToBlack")
