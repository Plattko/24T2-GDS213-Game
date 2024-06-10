class_name WeaponManager

extends Node3D

@export var current_weapon : Weapon
var weapons : Array = []

func _ready() -> void:
	weapons = get_children()

func _physics_process(delta):
	# Handle shooting
	if Input.is_action_pressed("shoot"):
		if !current_weapon.anim_player.is_playing():
			if current_weapon.cur_ammo > 0:
				current_weapon.shoot()
			else:
				current_weapon.reload()
	
	if Input.is_action_pressed("reload"):
		if !current_weapon.anim_player.is_playing() and current_weapon.cur_ammo < current_weapon.MAX_AMMO:
			current_weapon.reload()

