class_name Weapon

extends Node

# Reference variables
@onready var mesh = %Mesh
@onready var anim_player = %AnimationPlayer
@onready var muzzle_flash : MuzzleFlash = %MuzzleFlash

var bullet_decal = preload("res://Scenes/bullet_decal.tscn")

# Weapon data
@export_category("Weapon Data")
@export var BULLET_DAMAGE : float

@export var MAX_AMMO : int
@export var AMMO_COST := 1
var cur_ammo

@export var is_auto_fire : bool = true

# Animation variables
const SHOOT_ANIM : String = "Shoot"
const RELOAD_ANIM : String = "Reload"
const EQUIP_ANIM : String = "Equip"
const UNEQUIP_ANIM : String = "Unequip"

# Bullet hole variables
var decal_queue = []
const MAX_QUEUE_SIZE := 30

# Signals
signal update_ammo

func _ready():
	cur_ammo = MAX_AMMO

func shoot() -> void:
	# Display the muzzle flash
	muzzle_flash.add_muzzle_flash()
	
	anim_player.play(SHOOT_ANIM)
	
	cur_ammo -= AMMO_COST
	update_ammo.emit([cur_ammo, MAX_AMMO])

func reload() -> void:
	anim_player.play(RELOAD_ANIM)
	await anim_player.animation_finished
	cur_ammo = MAX_AMMO
	update_ammo.emit([cur_ammo, MAX_AMMO])

func spawn_decal(position: Vector3, normal: Vector3) -> void:
	# Instantiate bullet decal
	var instance = bullet_decal.instantiate()
	# Make it a child of the scene
	get_tree().root.add_child(instance)
	# Set its position
	instance.global_position = position
	
	if normal != Vector3.UP and normal != Vector3.DOWN:
		instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
		instance.rotate_object_local(Vector3(1, 0, 0), 90)
	
	update_decal_queue(instance)

func update_decal_queue(decal):
	decal_queue.push_back(decal)
	
	if decal_queue.size() > MAX_QUEUE_SIZE:
		var decal_to_destroy = decal_queue.pop_front()
		decal_to_destroy.queue_free()
