class_name DoSideTiltSetting
extends Control

signal side_tilt_mode_updated(mode: MultiplayerPlayer.Side_Tilt_Modes)

func _on_item_selected(index):
	
	match index:
		0: side_tilt_mode_updated.emit(MultiplayerPlayer.Side_Tilt_Modes.DEFAULT)
		1: side_tilt_mode_updated.emit(MultiplayerPlayer.Side_Tilt_Modes.GROUND_ONLY)
		2: side_tilt_mode_updated.emit(MultiplayerPlayer.Side_Tilt_Modes.NEVER)
		_: print("No index for selected side tilt mode.")
