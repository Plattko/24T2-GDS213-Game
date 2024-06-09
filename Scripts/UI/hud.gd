extends Control

@export var current_ammo_label : Label

func on_update_ammo(ammo):
	current_ammo_label.set_text("Ammo: " + str(ammo[0]) + "/" + str(ammo[1]))
