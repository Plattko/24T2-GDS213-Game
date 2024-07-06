class_name WeaponManager

extends Node3D

@export var weapon_switch_cooldown : Timer
var camera : Camera3D
var input : PlayerInput
var reticle : Reticle

var current_weapon : Weapon
var max_weapon_index : int
var weapon_index := 0

var weapons : Array[Weapon]

enum Reload_Types {
	AUTO,
	ON_SHOOT,
	MANUAL,
}

@export var reload_type : Reload_Types

func initialise(player_camera: Camera3D, player_input: PlayerInput, player_reticle: Reticle) -> void:
	camera = player_camera
	input = player_input
	reticle = player_reticle
	
	for child in get_children():
		if child is Weapon:
			weapons.append(child)
			child.mesh.visible = false
			child.init(camera)
	
	max_weapon_index = weapons.size() - 1
	current_weapon = weapons[0]
	current_weapon.mesh.visible = true
	current_weapon.update_ammo.emit([current_weapon.cur_ammo, current_weapon.MAX_AMMO])

func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	
	# Handle shooting
	if current_weapon.is_auto_fire:
		if input.is_shoot_pressed:
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				# Reload on shoot
				elif reload_type == Reload_Types.ON_SHOOT:
					current_weapon.reload()
	else:
		if input.is_shoot_just_pressed:
			if !current_weapon.anim_player.is_playing():
				if current_weapon.cur_ammo > 0:
					current_weapon.shoot()
				# Reload on shoot
				elif reload_type == Reload_Types.ON_SHOOT:
					current_weapon.reload()
	
	# Auto reload
	if current_weapon.cur_ammo <= 0 and reload_type == Reload_Types.AUTO:
		if !current_weapon.anim_player.is_playing():
			current_weapon.reload()
	
	if input.is_reload_pressed:
		if !current_weapon.anim_player.is_playing() and current_weapon.cur_ammo < current_weapon.MAX_AMMO:
			current_weapon.reload()
	
	if input.is_weapon_1_pressed:
		print("Pressed Weapon 1.")
		#if !current_weapon.anim_player.is_playing():
		if weapon_switch_cooldown.is_stopped():
			change_weapon(weapons[0])
	
	if input.is_weapon_2_pressed:
		print("Pressed Weapon 2.")
		#if !current_weapon.anim_player.is_playing():
		if weapon_switch_cooldown.is_stopped():
			change_weapon(weapons[1])
	
	if input.is_weapon_3_pressed:
		#if !current_weapon.anim_player.is_playing():
		if weapon_switch_cooldown.is_stopped():
			change_weapon(weapons[2])
	
	if input.weapon_scroll_direction:
		#if !current_weapon.anim_player.get_current_animation() == current_weapon.EQUIP_ANIM:
		if weapon_switch_cooldown.is_stopped():
			var dir = input.weapon_scroll_direction
			scroll_weapon(dir)

func scroll_weapon(dir: int) -> void:
	weapon_index += dir
	if weapon_index > max_weapon_index: weapon_index = 0
	if weapon_index < 0: weapon_index = max_weapon_index
	change_weapon(weapons[weapon_index])

func change_weapon(next_weapon: Weapon) -> void:
	if next_weapon != current_weapon:
		#current_weapon.anim_player.play(current_weapon.UNEQUIP_ANIM)
		#await current_weapon.anim_player.animation_finished
		
		weapon_switch_cooldown.start()
		current_weapon.anim_player.stop()
		current_weapon.mesh.visible = false
		
		if reticle:
			call_update_reticle(next_weapon)
		else:
			print("No reticle found.")
		
		next_weapon.update_ammo.emit([next_weapon.cur_ammo, next_weapon.MAX_AMMO])
		next_weapon.anim_player.play(next_weapon.EQUIP_ANIM)
		current_weapon = next_weapon

func call_update_reticle(weapon: Weapon) -> void:
	reticle.update_reticle(weapon)

func set_reload_type(type: Reload_Types):
	reload_type = type
