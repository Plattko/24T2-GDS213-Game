class_name InputInterceptor
extends Panel

var input_rebind_button : InputRebindButton

func _ready() -> void:
	hide()

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_double_click():
			event.double_click = false
		input_rebind_button.rebind_input_action(event)

func activate(button: InputRebindButton) -> void:
	input_rebind_button = button
	show()

func deactivate() -> void:
	input_rebind_button = null
	hide()
