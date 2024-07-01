class_name Debug

extends PanelContainer

@export var property_container : VBoxContainer

var frames_per_second : String

func _ready():
	visible = false

func _input(event):
	# Toggle debug panel
	if event.is_action_pressed("debug"):
		visible = !visible

func _process(delta):
	if visible:
		# Get frames per second
		frames_per_second = str(snappedf(1.0 / delta, 1))
		add_debug_property("FPS", frames_per_second, 0)

func add_debug_property(title: String, value, order):
	var target
	# Check if the target already exists
	target = property_container.find_child(title, true, false)
	
	if !target:
		target = Label.new()
		property_container.add_child(target)
		target.name = title
		target.text = title + ": " + str(value)
	elif visible:
		target.text = title + ": " + str(value)
		property_container.move_child(target, order)
