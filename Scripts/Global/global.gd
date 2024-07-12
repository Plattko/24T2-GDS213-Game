extends Node

var camera

# TODO: Test if this quits other clients' games
func _input(event):
	# Handle quit
	if event.is_action_pressed("quit"):
		get_tree().quit()
