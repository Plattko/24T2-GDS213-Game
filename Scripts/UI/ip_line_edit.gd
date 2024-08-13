extends LineEdit

var regex = RegEx.new()
var old_text = ""

func _ready() -> void:
	# Sets it to check for the numbers 0-9 and "."
	regex.compile("^[0-9.]*$")
	# Connect the text changed signal to the function
	text_changed.connect(on_text_changed)

func on_text_changed(new_text):
	# Checks if the new text contains only the numbers 0-9 or "."
	if regex.search(new_text):
		# If it does, sets the old text to the new text
		old_text = str(new_text)
	else:
		# If it doesn't, sets the LineEdit text to the old text and puts the caret column back where it was
		var cached_caret_column = caret_column
		text = old_text
		set_caret_column(cached_caret_column - 1)

