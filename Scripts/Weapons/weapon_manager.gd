class_name WeaponManager

extends Node3D

var current_weapon : Weapon

var weapons : Array[Weapon]

func _ready() -> void:
	for child in get_children():
		if child is Weapon:
			weapons.append(child)
			child.mesh.visible = false
	
	current_weapon = weapons[0]
	current_weapon.mesh.visible = true
	current_weapon.update_ammo.emit([current_weapon.cur_ammo, current_weapon.MAX_AMMO])

func _physics_process(delta):
	# Handle shooting
	if current_weapon.is_auto_fire:
		if Input.is_action_pressed("shoot"):
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				else:
					current_weapon.reload()
	else:
		if Input.is_action_just_pressed("shoot"):
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				else:
					current_weapon.reload()
	
	if Input.is_action_pressed("reload"):
		if !current_weapon.anim_player.is_playing() and current_weapon.cur_ammo < current_weapon.MAX_AMMO:
			current_weapon.reload()
	
	if Input.is_action_pressed("weapon_1"):
		if !current_weapon.anim_player.is_playing():
			change_weapon(weapons[0])
	
	if Input.is_action_pressed("weapon_2"):
		if !current_weapon.anim_player.is_playing():
			change_weapon(weapons[1])

func change_weapon(next_weapon: Weapon) -> void:
	if next_weapon != current_weapon:
		current_weapon.anim_player.play(current_weapon.UNEQUIP_ANIM)
		await current_weapon.anim_player.animation_finished
		next_weapon.update_ammo.emit([next_weapon.cur_ammo, next_weapon.MAX_AMMO])
		next_weapon.anim_player.play(next_weapon.EQUIP_ANIM)
		current_weapon = next_weapon

