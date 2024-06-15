extends Control

@export var health_label : Label
@export var current_ammo_label : Label

func on_update_health(health):
	health_label.text = "Health: " + str(health[0]) + "/" + str(health[1])

func on_update_ammo(ammo):
	current_ammo_label.set_text("Ammo: " + str(ammo[0]) + "/" + str(ammo[1]))
