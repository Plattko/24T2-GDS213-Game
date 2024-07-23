class_name EnemyHealthBar
extends ProgressBar

@export var dmg_bar : ProgressBar
@export var display_timer : Timer

var cur_health : float

func _ready() -> void:
	visible = false

func init_health(health: float) -> void:
	cur_health = health
	
	max_value = cur_health
	value = cur_health
	
	dmg_bar.max_value = cur_health
	dmg_bar.value = cur_health

func update_health(new_health: float, is_crit: bool) -> void:
	visible = true
	display_timer.start()
	
	var prev_health : float = cur_health
	cur_health = min(max_value, new_health)
	value = cur_health
	
	# Delete health bar if health reaches 0
	if cur_health <= 0.0:
		queue_free()
	
	# Enemy took damage
	if cur_health < prev_health:
		if is_crit:
			var style_box : StyleBoxFlat = dmg_bar.get_theme_stylebox("fill").duplicate()
			style_box.set("bg_color", Color(0.961, 0.717, 0.068))
			dmg_bar.add_theme_stylebox_override("fill", style_box)
		
		var tween : Tween = create_tween()
		if is_crit:
			tween.finished.connect(reset_dmg_bar_colour)
		tween.tween_property(dmg_bar, "value", cur_health, 0.4)
	# Enemy healed
	else:
		dmg_bar.value = cur_health

func reset_dmg_bar_colour() -> void:
	var style_box : StyleBoxFlat = dmg_bar.get_theme_stylebox("fill").duplicate()
	style_box.set("bg_color", Color.WHITE)
	dmg_bar.add_theme_stylebox_override("fill", style_box)

func _on_display_timer_timeout():
	visible = false
