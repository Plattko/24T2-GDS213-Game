extends MeshInstance3D

var max_health := 100
var cur_health

func _ready():
	cur_health = max_health
	
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)
		else:
			push_warning("Object contains non-damageable child node.")

func on_damaged(damage: float):
	cur_health -= damage
	
	if cur_health <= 0:
		queue_free()
