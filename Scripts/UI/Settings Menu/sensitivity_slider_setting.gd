class_name SensitivitySetting

extends Control

@export var slider : HSlider
@export var num_label : Label

signal sensitivity_updated(value: float)

func _on_slider_value_changed(value) -> void:
	set_sensitivity()
	set_num_label_text()

func set_sensitivity() -> void:
	var sensitivity = slider.value / 100.0
	print("Sensitivity: " + str(slider.value / 100.0))
	sensitivity_updated.emit(sensitivity)

func set_num_label_text() -> void:
	num_label.text = str(slider.value) + "%"
