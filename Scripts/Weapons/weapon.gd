class_name Weapon

extends Node

var camera : Camera3D

# Reference variables
@onready var mesh = %Mesh
@onready var anim_player = %AnimationPlayer
@export var muzzle_flash : MuzzleFlash

var bullet_decal = preload("res://Scenes/Weapons/Components/bullet_decal.tscn")

# Weapon data
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

const HITSCAN_COLLISION_MASK := roundi(pow(2, 1-1)) + roundi(pow(2, 4-1))

# Animation variables
const SHOOT_ANIM : String = "Shoot"
const RELOAD_ANIM : String = "Reload"
const EQUIP_ANIM : String = "Equip"
const UNEQUIP_ANIM : String = "Unequip"

# Bullet hole variables
var decal_queue = []
const MAX_QUEUE_SIZE := 100

# Signals
signal update_ammo
signal regular_hit(damage: float)
signal crit_hit(damage: float)

func _ready():
	cur_ammo = MAX_AMMO

func init(player_camera: Camera3D) -> void:
	camera = player_camera

func shoot() -> void:
	# Display the muzzle flash
	if muzzle_flash: muzzle_flash.add_muzzle_flash.rpc()
	anim_player.play(SHOOT_ANIM)
	
	cur_ammo -= AMMO_COST
	update_ammo.emit([cur_ammo, MAX_AMMO])

func reload() -> void:
	anim_player.play(RELOAD_ANIM, -1, 0.5)

func reset_ammo() -> void:
	cur_ammo = MAX_AMMO
	update_ammo.emit([cur_ammo, MAX_AMMO])

func spawn_decal(position: Vector3, normal: Vector3) -> void:
	# Instantiate bullet decal
	var instance = bullet_decal.instantiate()
	# Make it a child of the level scene
	var level = get_tree().get_first_node_in_group("level")
	level.add_child(instance)
	# Set its position
	instance.global_position = position
	# Give the decal a reference to the decal queue
	instance.decal_queue = decal_queue
	# Rotate the decal in the direction of the surface's normal
	if abs(normal.y) < 0.99:
		instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
		instance.rotate_object_local(Vector3(1, 0, 0), 90)
	# Add random rotation around the decal's local Y axis
	instance.rotate_object_local(Vector3(0,1,0), randf_range(0.0,360.0))
	
	update_decal_queue(instance)

func update_decal_queue(decal):
	decal_queue.push_back(decal)
	
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

