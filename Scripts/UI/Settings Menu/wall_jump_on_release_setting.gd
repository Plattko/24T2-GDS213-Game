class_name WallJumpOnReleaseSetting
extends Control

signal wall_jump_on_release_updated(wall_jump_on_release: bool)

func _on_item_selected(index):
	
	match index:
		0: wall_jump_on_release_updated.emit(false)
		1: wall_jump_on_release_updated.emit(true)
		_: print("No index for selected wall jump mode.")
