class_name Weapon

extends Node

var camera : Camera3D

@export_group("Reference Variables")
@export var mesh : MeshInstance3D
@export var muzzle_flash : MuzzleFlash
@export var anim_player : AnimationPlayer

#var third_person_material = load("res://Assets/Materials/Shader Materials/weapon_third_person_shader.tres")
var third_person_material = load("res://Assets/Materials/Standard Materials/weapon_third_person_material.tres")
var bullet_decal = load("res://Scenes/Weapons/Components/bullet_decal.tscn")
var sparks_particle = load("res://Scenes/VFX/sparks_particle.tscn")

@export_group("Weapon Data")
@export_subgroup("Damage")
@export var BULLET_DAMAGE : float
@export var CRIT_MULTIPLIER : float = 2.0
var crit_damage : float:
	get: return BULLET_DAMAGE * CRIT_MULTIPLIER

@export_subgroup("Damage Falloff")
@export var FALLOFF_NEAR_DIST : float
@export var FALLOFF_FAR_DIST : float
@export var MAX_FALLOFF_MOD : float

@export_subgroup("Ammo")
@export var MAX_AMMO : int
@export var AMMO_COST := 1
var cur_ammo

@export var is_auto_fire : bool = true

const HITSCAN_RAY_RANGE := 2000.0
const HITSCAN_COLLISION_MASK := roundi(pow(2, 1-1)) + roundi(pow(2, 4-1))

# Animation variables
const SHOOT_ANIM : String = "Shoot"
const RELOAD_ANIM : String = "Reload"
const EQUIP_ANIM : String = "Equip"

# Bullet hole variables
var decal_queue = []
const MAX_QUEUE_SIZE := 100

# Signals
signal update_ammo
signal regular_hit(damage: float)
signal crit_hit(damage: float)

func _ready():
	# Set weapon meshes to the third person material if not the player holding the weapon
	if !is_multiplayer_authority():
		mesh.set_surface_override_material(0, third_person_material)
		for child_mesh in mesh.get_children():
			if child_mesh is MeshInstance3D:
				child_mesh.set_surface_override_material(0, third_person_material)
	
	cur_ammo = MAX_AMMO

func init(player_camera: Camera3D) -> void:
	camera = player_camera

func shoot() -> void:
	# Display the muzzle flash
	if muzzle_flash: muzzle_flash.add_muzzle_flash.rpc()
	# Play the shoot animation
	play_anim.rpc(SHOOT_ANIM)
	# Decrease the ammo by the ammo cose
	cur_ammo -= AMMO_COST
	# Update the ammo on the UI
	update_ammo.emit([cur_ammo, MAX_AMMO])

func reload() -> void:
	# Play the reload animation
	play_anim.rpc(RELOAD_ANIM, 0.5)

func reset_ammo() -> void:
	# Set the ammo back to the max ammo
	cur_ammo = MAX_AMMO
	# Update the ammo on the UI
	update_ammo.emit([cur_ammo, MAX_AMMO])

func raycast_hit(result: Dictionary) -> void:
	# Get the hit object's collider
	var collider = result.collider
	# If the collider is damageable apply the damage and signal a hit, otherwise spawn a bullet hole decal
	if collider is Damageable:
		# Calculate the distance of the hit from the player
		var distance = Vector3(collider.global_position - camera.global_position).length()
		# Apply damage with fall off and signal the hit
		if collider.is_weak_point:
			var dmg = damage_with_falloff(crit_damage, distance)
			collider.take_damage.rpc(dmg, true)
			crit_hit.emit(dmg)
		else:
			var dmg = damage_with_falloff(BULLET_DAMAGE, distance)
			collider.take_damage.rpc(dmg, false)
			regular_hit.emit(dmg)
		# Spawn the sparks particle effect
		spawn_sparks(result.get("position"), result.get("normal"))
	else:
		# Spawn a bullet hole decal
		spawn_decal(result.get("position"), result.get("normal"))

func spawn_decal(position: Vector3, normal: Vector3) -> void:
	# Instantiate bullet decal
	var instance = bullet_decal.instantiate()
	# Give it a reference to the decal queue
	instance.decal_queue = decal_queue
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(instance)
	# Set its position
	instance.global_position = position
	# Rotate it in the direction of the surface's normal
	if abs(normal.y) < 0.99:
		instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
		instance.rotate_object_local(Vector3(1, 0, 0), 90)
	# Add random rotation around the decal's local Y axis
	instance.rotate_object_local(Vector3(0,1,0), randf_range(0.0,360.0))
	# Update the decal queue
	update_decal_queue(instance)

func spawn_sparks(pos: Vector3, normal: Vector3) -> void:
	# Instantiate the sparks particle
	var sparks = sparks_particle.instantiate() as Node3D
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(sparks)
	# Set its position
	sparks.global_position = pos
	# Make it fire in the direction of the collider's normal
	sparks.look_at(pos + normal, Vector3.UP)
	sparks.look_at(pos + normal, Vector3.RIGHT)

func update_decal_queue(decal):
	# Add the new decal to the end of the queue
	decal_queue.push_back(decal)
	# If the queue size is greater than the max queue size, remove and destroy the decal at the front of the queue
	if decal_queue.size() > MAX_QUEUE_SIZE:
		var decal_to_destroy = decal_queue.pop_front()
		decal_to_destroy.queue_free()

func damage_with_falloff(damage: float, distance: float) -> float:
	# Calculate the minimum damage
	var min_dmg = damage * MAX_FALLOFF_MOD
	# Calculate the normalised distance in relation to the falloff range
	var dist_normalised = clampf((distance - FALLOFF_NEAR_DIST)/(FALLOFF_FAR_DIST - FALLOFF_NEAR_DIST), 0, 1)
	# Calculate how much of the minimum and maximum damage should be dealt
	return dist_normalised * min_dmg + (1.0 - dist_normalised) * damage

#-------------------------------------------------------------------------------
# RPCs
#-------------------------------------------------------------------------------
@rpc("call_local")
func play_anim(anim: String, custom_speed: float = 1.0) -> void:
	anim_player.play(anim, -1, custom_speed)

@rpc("call_local")
func stop_anim() -> void:
	anim_player.stop()
