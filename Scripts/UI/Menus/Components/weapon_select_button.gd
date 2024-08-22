class_name WeaponSelectButton
extends Button

var weapon_name : String = ""

signal weapon_select_button_pressed(button: WeaponSelectButton)

func _ready() -> void:
	pressed.connect(on_pressed)
	text = ""

func on_pressed() -> void:
	weapon_select_button_pressed.emit(self)
