class_name AutoSprintSetting
extends Control

signal do_auto_sprint_updated(do_auto_sprint: bool)

func _on_item_selected(index):
	
	match index:
		0: do_auto_sprint_updated.emit(true)
		1: do_auto_sprint_updated.emit(false)
		_: print("No index for selected auto sprint mode.")
