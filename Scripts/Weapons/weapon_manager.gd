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
var primary_weapon : String
var secondary_weapon : String

enum Reload_Types { AUTO, ON_SHOOT, MANUAL, }
@export var reload_type : Reload_Types

func initialise(player_camera: Camera3D, player_input: PlayerInput, player_reticle: Reticle, _primary_weapon: String, _secondary_weapon: String) -> void:
	camera = player_camera
	input = player_input
	reticle = player_reticle
	primary_weapon = _primary_weapon
	secondary_weapon = _secondary_weapon
	
	for child in get_children():
		if child is Weapon:
			if child.name == primary_weapon:
				move_child(child, 0)
				weapons.push_front(child)
				child.mesh.visible = false
				child.init(camera)
			elif child.name == secondary_weapon:
				move_child(child, 1)
				weapons.append(child)
				child.mesh.visible = false
				child.init(camera)	
			else:
				child.queue_free()
	
	max_weapon_index = weapons.size() - 1
	current_weapon = weapons[0]
	current_weapon.mesh.visible = true
	current_weapon.update_ammo.emit([current_weapon.cur_ammo, current_weapon.MAX_AMMO])
	reticle.update_reticle(current_weapon)

func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	
	# Handle shooting
	if current_weapon.is_auto_fire:
		if input.is_shoot_pressed:
			shoot_weapon()
	else:
		if input.is_shoot_just_pressed:
			shoot_weapon()
	
	# Auto reload
	if current_weapon.cur_ammo <= 0 and reload_type == Reload_Types.AUTO:
		if !current_weapon.anim_player.is_playing():
			current_weapon.reload()
	
	# Manual reload
	if input.is_reload_pressed:
		if !current_weapon.anim_player.is_playing() and current_weapon.cur_ammo < current_weapon.MAX_AMMO:
			current_weapon.reload()
	
	if input.is_weapon_1_pressed:
		#print("Pressed Weapon 1.")
		if weapon_switch_cooldown.is_stopped():
			change_weapon(0)
	
	if input.is_weapon_2_pressed:
		#print("Pressed Weapon 2.")
		if weapon_switch_cooldown.is_stopped():
			change_weapon(1)
	
	#if input.is_weapon_3_pressed:
		##print("Pressed Weapon 3.")
		#if weapon_switch_cooldown.is_stopped():
			#change_weapon(2)
	
	if input.weapon_scroll_direction:
		if weapon_switch_cooldown.is_stopped():
			var dir = input.weapon_scroll_direction
			scroll_weapon(dir)

func shoot_weapon() -> void:
	if !current_weapon.anim_player.is_playing():
		if current_weapon.cur_ammo > 0:
			current_weapon.shoot()
		# Reload on shoot
		elif reload_type == Reload_Types.ON_SHOOT:
			current_weapon.reload()

func scroll_weapon(dir: int) -> void:
	var index = weapon_index + dir
	if index > max_weapon_index: index = 0
	elif index < 0: index = max_weapon_index
	change_weapon(index)

func change_weapon(index: int) -> void:
	var next_weapon = weapons[index]
	if next_weapon != current_weapon:
		weapon_index = index
		weapon_switch_cooldown.start()
		current_weapon.stop_anim.rpc()
		current_weapon.mesh.visible = false
		
		if reticle: call_update_reticle(next_weapon)
		else: print("No reticle found.")
		
		next_weapon.update_ammo.emit([next_weapon.cur_ammo, next_weapon.MAX_AMMO])
		#next_weapon.anim_player.play(next_weapon.EQUIP_ANIM)
		next_weapon.play_anim.rpc(next_weapon.EQUIP_ANIM)
		current_weapon = next_weapon

func reset_weapon() -> void:
	# Reset current weapon
	current_weapon = weapons[0]
	# Reset weapon index
	weapon_index = 0
	# Reset reticle
	call_update_reticle(current_weapon)
	# Reset all guns to max ammo
	for weapon in weapons:
		weapon.cur_ammo = weapon.MAX_AMMO
	# Update the ammo UI
	current_weapon.update_ammo.emit([current_weapon.cur_ammo, current_weapon.MAX_AMMO])
	# Play the equip animation
	current_weapon.play_anim.rpc(current_weapon.EQUIP_ANIM)

func call_update_reticle(weapon: Weapon) -> void:
	reticle.update_reticle(weapon)

func set_reload_type(type: Reload_Types):
	reload_type = type
