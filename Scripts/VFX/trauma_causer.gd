extends Area3D

@export var trauma_amount : float = 0.1
@export var unlimited_range : bool = false

func cause_trauma() -> void:
	var trauma_areas
	if unlimited_range:
		trauma_areas = get_tree().get_nodes_in_group("shakeable_areas")
	else:
		trauma_areas = get_overlapping_areas()
	for area in trauma_areas:
		if area is ShakeableCamera:
			area.add_trauma(trauma_amount)
