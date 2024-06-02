class_name AirPlayerState

extends PlayerState

func enter():
	print("Entered Air player state.")

func physics_update(delta : float):
	if player.is_on_floor():
		transition.emit("IdlePlayerState")
		return
