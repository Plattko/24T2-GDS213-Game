class_name WeaponSelectButton
extends Button

@export var button : Button
var weapon_name : String = ""

signal weapon_select_button_pressed(button: WeaponSelectButton)

func _ready() -> void:
	pressed.connect(on_pressed)
	if weapon_name != "":
		name = weapon_name + "Button"
		button.text = weapon_name

func on_pressed() -> void:
	weapon_select_button_pressed.emit(self)
