extends Control

@export var health_label : Label
@export var cur_ammo_label : Label

@export var cur_wave_label : Label
@export var enemies_left_label : Label

var wave_manager : WaveManager

func _ready():
	cur_wave_label.visible = false
	enemies_left_label.visible = false
	
	wave_manager = get_tree().get_first_node_in_group("WaveManager")
	wave_manager.cur_wave_updated.connect(on_cur_wave_updated)
	wave_manager.enemy_count_updated.connect(on_enemy_count_updated)
	wave_manager.intermission_entered.connect(on_intermission_entered)

func on_update_health(health) -> void:
	health_label.text = "Health: " + str(health[0]) + "/" + str(health[1])

func on_update_ammo(ammo) -> void:
	cur_ammo_label.set_text("Ammo: " + str(ammo[0]) + "/" + str(ammo[1]))

func on_cur_wave_updated(wave: int) -> void:
	cur_wave_label.text = "Wave " + str(wave)
	if !cur_wave_label.visible:
		cur_wave_label.visible = true
	if !enemies_left_label.visible:
		enemies_left_label.visible = true

func on_enemy_count_updated(enemy_count: int) -> void:
	enemies_left_label.text = "Enemies Remaining: " + str(enemy_count)

func on_intermission_entered() -> void:
	cur_wave_label.text = "Intermission"
	if enemies_left_label.visible:
		enemies_left_label.visible = false
