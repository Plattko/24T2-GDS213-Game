class_name ReloadTypeSetting

extends Control

func _on_item_selected(index):
	var weapon_manager = Global.player.weapon_manager
	
	match index:
		0: weapon_manager.reload_type = weapon_manager.Reload_Types.AUTO
		1: weapon_manager.reload_type = weapon_manager.Reload_Types.ON_SHOOT
		2: weapon_manager.reload_type = weapon_manager.Reload_Types.MANUAL
		_: print("No index for selected reload type.")
