class_name ReloadTypeSetting

extends Control

signal reload_type_updated(type: WeaponManager.Reload_Types)

func _on_item_selected(index):
	
	match index:
		0: reload_type_updated.emit(WeaponManager.Reload_Types.AUTO)
		1: reload_type_updated.emit(WeaponManager.Reload_Types.ON_SHOOT)
		2: reload_type_updated.emit(WeaponManager.Reload_Types.MANUAL)
		_: print("No index for selected reload type.")
