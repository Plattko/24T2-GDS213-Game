extends Node

@export var multiplayer_hud : Control

func become_host() -> void:
	print("Pressed Host New Game.")
	multiplayer_hud.hide()
	MultiplayerManager.become_host()

func join_as_player_2() -> void:
	print("Pressed Join as Player 2.")
	multiplayer_hud.hide()
	MultiplayerManager.join_as_player_2()
