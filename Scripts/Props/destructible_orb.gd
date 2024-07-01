extends MeshInstance3D

var max_health := 50
var cur_health

signal orb_destroyed

func _ready():
	cur_health = max_health
	
	for child in get_children():
		if child is Damageable:
			# Connect each damageable to the damaged signal
			child.damaged.connect(on_damaged)

func _physics_process(delta):
	if cur_health <= 0:
		orb_destroyed.emit()
		queue_free()

func on_damaged(damage: float):
	cur_health -= damage
