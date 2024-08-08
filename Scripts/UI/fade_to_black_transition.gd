class_name FadeToBlackTransition
extends Control

@export var anim_player : AnimationPlayer

func _ready() -> void:
	anim_player.play("FadeToBlack")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "FadeToBlack":
		queue_free()
