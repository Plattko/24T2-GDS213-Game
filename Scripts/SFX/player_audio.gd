extends Node

@export var NormalHitmarker: AudioStreamPlayer
@export var HeadshotHitmarker: AudioStreamPlayer

func PlayNormalHitmarker(_dmg):
	NormalHitmarker.play()

func PlayHeadshotHitmarker(_dmg):
	HeadshotHitmarker.play()
