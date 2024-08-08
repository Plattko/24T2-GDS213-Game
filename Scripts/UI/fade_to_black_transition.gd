class_name FadeToBlackTransition
extends Control

@export var anim_player : AnimationPlayer

func _ready() -> void:
	anim_player.play("FadeToBlack")
