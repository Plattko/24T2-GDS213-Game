extends Panel

@export var property_container : VBoxContainer

var property
var frames_per_second : String

func _ready():
	visible = false
	
	add_debug_property("FPS", frames_per_second)

func _input(event):
	# Toggle debug panel
	if event.is_action_pressed("debug"):
		visible = !visible

func _process(delta):
	if visible:
		# Get frames per second
		frames_per_second = "%.2f" % (1.0 / delta)
		property.text = property.name + ": " + frames_per_second

func add_debug_property(title : StringName, value):
	property = Label.new()
	property_container.add_child(property)
	property.name = title
	property.text = property.name + value
