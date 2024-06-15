class_name WeaponManager

extends Node3D

@onready var settings_menu = %SettingsMenu
var input : PlayerInput

var current_weapon : Weapon

var weapons : Array[Weapon]

func initialise(player_input: PlayerInput) -> void:
	input = player_input
	
	handle_connected_signals()
	
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
		if input.is_shoot_pressed():
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				else:
					current_weapon.reload()
	else:
		if input.is_shoot_just_pressed():
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				else:
					current_weapon.reload()
	
	if input.is_reload_pressed():
		if !current_weapon.anim_player.is_playing() and current_weapon.cur_ammo < current_weapon.MAX_AMMO:
			current_weapon.reload()
	
	if input.is_weapon_1_pressed():
		if !current_weapon.anim_player.is_playing():
			change_weapon(weapons[0])
	
	if input.is_weapon_2_pressed():
		if !current_weapon.anim_player.is_playing():
			change_weapon(weapons[1])
	
	if input.is_weapon_3_pressed():
		if !current_weapon.anim_player.is_playing():
			change_weapon(weapons[2])

func change_weapon(next_weapon: Weapon) -> void:
	if next_weapon != current_weapon:
		current_weapon.anim_player.play(current_weapon.UNEQUIP_ANIM)
		await current_weapon.anim_player.animation_finished
		next_weapon.update_ammo.emit([next_weapon.cur_ammo, next_weapon.MAX_AMMO])
		next_weapon.anim_player.play(next_weapon.EQUIP_ANIM)
		current_weapon = next_weapon

func handle_connected_signals() -> void:
	settings_menu.opened_settings_menu.connect(disable_input)
	settings_menu.closed_settings_menu.connect(enable_input)

func disable_input() -> void:
	print("Disabled Weapon Manager input.")

func enable_input() -> void:
	print("Enabled Weapon Manager input.")
