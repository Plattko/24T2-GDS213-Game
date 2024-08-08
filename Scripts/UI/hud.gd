class_name HUD
extends Control

@export_group("Health and Weapons UI")
@export var health_label : Label
@export var cur_ammo_label : Label
@export var reticle : Reticle

@export_group("Wave and Zone UI")
@export var cur_wave_label : Label
@export var enemies_left_label : Label

@export var zone_change_warning : PanelContainer
@export var time_text : Label

@export_group("Downed UI")
@export var downed_ui : Control
@export var death_timer_text : Label
@export var death_progress_bar : TextureProgressBar

@export_group("Dead UI")
@export var dead_ui : Control
@export var respawn_text : Label
@export var respawn_timer_text : Label
@export var respawn_progress_bar : TextureProgressBar

@export_group("Interact UI")
@export var interact_ui : Control
@export var interact_text : Label
@export var interact_key_text : Label
@export var interact_progress_bar : TextureProgressBar
var is_interacting : bool = false

var death_timer : Timer
var respawn_timer : Timer
var revive_other_timer : Timer

var wave_manager : WaveManager

func _ready():
	cur_wave_label.visible = false
	enemies_left_label.visible = false
	zone_change_warning.visible = false
	downed_ui.hide()
	dead_ui.hide()
	interact_ui.hide()
	
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if (wave_manager):
		wave_manager.cur_wave_updated.connect(on_cur_wave_updated)
		wave_manager.enemy_count_updated.connect(on_enemy_count_updated)
		wave_manager.intermission_entered.connect(on_intermission_entered)
		wave_manager.zone_change_entered.connect(on_zone_change_entered)
		wave_manager.zone_change_timer.timeout.connect(_on_zone_change_timer_timeout)

func init(_death_timer: Timer, _respawn_timer: Timer, _revive_other_timer: Timer) -> void:
	death_timer = _death_timer
	respawn_timer = _respawn_timer
	revive_other_timer = _revive_other_timer

func _process(_delta) -> void:
	if zone_change_warning.visible:
		time_text.text = str(snapped(wave_manager.zone_change_timer.time_left, 1))
	
	if cur_wave_label.text == "Intermission":
		enemies_left_label.text = "Next Wave In: " + str(snapped(wave_manager.intermission_timer.time_left, 1))
	
	if downed_ui.visible:
		death_timer_text.text = str(snapped(death_timer.time_left, 1))
		death_progress_bar.value = death_timer.time_left
	
	if dead_ui.visible:
		respawn_timer_text.text = str(snapped(respawn_timer.time_left, 1))
		respawn_progress_bar.value = respawn_timer.time_left
	
	if interact_progress_bar.is_visible_in_tree():
		if is_interacting:
			interact_progress_bar.value = interact_progress_bar.max_value - revive_other_timer.time_left
		else:
			interact_progress_bar.value = 0.0

func on_update_health(health) -> void:
	health_label.text = "Health: " + str(roundi(health[0])) + "/" + str(health[1])

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

func on_player_downed() -> void:
	death_progress_bar.max_value = death_timer.wait_time
	reticle.hide_reticle()
	downed_ui.show()

func on_player_revived() -> void:
	reticle.show_reticle()
	downed_ui.hide()

func on_player_died(is_vaporised: bool) -> void:
	# Hide health, ammo and reticle
	health_label.hide()
	cur_ammo_label.hide()
	reticle.hide_reticle()
	# Hide the downed UI
	if downed_ui.visible: downed_ui.hide()
	# Show the dead UI
	if is_vaporised:
		respawn_progress_bar.max_value = respawn_timer.wait_time
		respawn_text.text = "Respawning in"
		respawn_progress_bar.show()
	else:
		respawn_text.text = "Respawning at next Intermission"
		respawn_progress_bar.hide()
	dead_ui.show()

func on_player_respawned() -> void:
	# Show health, ammo and reticle
	health_label.show()
	cur_ammo_label.show()
	reticle.show_reticle()
	# Hide the dead UI
	dead_ui.hide()

func on_interactable_focused(_interact_text: String, _interact_key: String) -> void:
	interact_text.text = _interact_text
	interact_key_text.text = _interact_key
	interact_progress_bar.max_value = revive_other_timer.wait_time
	if !interact_ui.visible:
		interact_ui.show()

func on_interactable_unfocused() -> void:
	if interact_ui.visible:
		interact_ui.hide()

func on_revive_started() -> void:
	if !is_interacting: is_interacting = true

func on_revive_stopped() -> void:
	if is_interacting: is_interacting = false

#-------------------------------------------------------------------------------
# Zone Change Sequence
#-------------------------------------------------------------------------------
func on_zone_change_entered() -> void:
	cur_wave_label.visible = false
	zone_change_warning.visible = true
	if enemies_left_label.visible:
		enemies_left_label.visible = false

func _on_zone_change_timer_timeout() -> void:
	zone_change_warning.visible = false
