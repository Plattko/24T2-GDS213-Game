class_name SensitivitySetting

extends Control

@export var slider : HSlider
@export var num_label : Label

func _on_slider_value_changed(value) -> void:
	set_sensitivity()
	set_num_label_text()

func set_sensitivity() -> void:
	Global.player.sensitivity = slider.value / 100.0 # TODO Must be made to work without global reference for multiplayer
	print("Sensitivity: " + str(slider.value / 100.0))

func set_num_label_text() -> void:
	num_label.text = str(slider.value) + "%"
