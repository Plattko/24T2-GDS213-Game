extends Decal

var decal_queue : Array = []

func _ready():
	set_process(false)

func _on_timer_timeout():
	set_process(true)

func _process(_delta):
	# Checks if decal was already queued for deletion by the decal queue
	if is_queued_for_deletion():
		return
	# Tweens the decal's alpha to zero
	var fade = get_tree().create_tween()
	fade.tween_property(self, "modulate:a", 0, 1.0)
	# Removes the decal from the weapon's decal queue and queues it for deletion
	await fade.finished
	decal_queue.erase(self)
	queue_free()
