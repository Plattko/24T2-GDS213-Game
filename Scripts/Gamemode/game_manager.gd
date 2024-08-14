extends Node

var main_menu := load("res://Scenes/UI/Menus/main_menu.tscn")
var is_using_steam : bool = false

func _input(event):
	# Handle quit
	if event.is_action_pressed("quit"):
		print(multiplayer.multiplayer_peer)
		# If the player is offline, close the game
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			print("Offline")
			get_tree().quit()
		# Otherwise, close the connection (sends player back to main menu and makes them offline)
		else:
			multiplayer.multiplayer_peer.close()
