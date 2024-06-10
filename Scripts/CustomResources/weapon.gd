class_name Weapon

extends Resource

@export var name : StringName

@export_category("Orientation Settings")
@export var position : Vector3
@export var rotation : Vector3

@export_category("Visual Settings")
@export var mesh : Mesh

@export_category("Animations")
@export var equip_anim : String
@export var unequip_anim : String
@export var shoot_anim : String
@export var reload_anim : String
@export var no_ammo_anim : String

@export_category("Weapon Data")
@export var MAX_AMMO : int
@export var cur_ammo : int

@export var auto_fire : bool

@export var damage : float

#@export var has_damage_fall_off : bool
#@export var fall_off_range : float
#@export var min_damage : float
