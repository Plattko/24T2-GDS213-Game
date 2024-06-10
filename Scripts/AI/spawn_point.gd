extends Node3D


@onready var visible_on_screen_notifier_3d = $VisibleOnScreenNotifier3D

var is_visible = false

# Signal for when the spawn point is visible to the player
func _on_visible_on_screen_notifier_3d_screen_entered():
	is_visible = true
	print("Spawn point is visible")

# Signal for when the spawn point is not visible to the player
func _on_visible_on_screen_notifier_3d_screen_exited():
	is_visible = false
	print("Spawn point is hidden")

# Function to check if the spawn point is hidden and available for spawning
func is_available_for_spawn() -> bool:
	return not is_visible
