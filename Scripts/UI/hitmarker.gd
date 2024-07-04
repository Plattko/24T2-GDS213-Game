class_name Hitmarker
extends CenterContainer

@export var reg_anim_player : AnimationPlayer
@export var crit_anim_player : AnimationPlayer
@export var reg_hit_markers : Array[Line2D] = []
@export var crit_hit_markers : Array[Line2D] = []

var recent_dmg : float
var max_recent_dmg := 200.0
var drain_rate := 50.0

var hit_min_length := 1.0
var reg_hit_max_length := 3.0
var crit_hit_max_length := 6.0

func _ready() -> void:
	# Hide hitmarkers
	for reg_hm in reg_hit_markers:
		reg_hm.default_color.a = 0
	for crit_hm in crit_hit_markers:
		crit_hm.default_color.a = 0

func _process(delta) -> void:
	if reg_hit_markers[0].default_color.a > 0 or crit_hit_markers[0].default_color.a > 0:
		recent_dmg -= drain_rate * delta
	else:
		recent_dmg -= drain_rate * delta * 4
	
	recent_dmg = clampf(recent_dmg, 0, max_recent_dmg)
	
	print(recent_dmg)

func on_regular_hit(damage: float) -> void:
	display_hitmarker(damage, reg_hit_markers, reg_hit_max_length, reg_anim_player, "RegHit")

func on_crit_hit(damage: float) -> void:
	display_hitmarker(damage, crit_hit_markers, crit_hit_max_length, crit_anim_player, "CritHit")

func display_hitmarker(damage: float, hitmarkers: Array[Line2D], hit_max_length: float, anim_player: AnimationPlayer, anim_name: String) -> void:
	# Add damage to recent damage
	recent_dmg += damage
	recent_dmg = clampf(recent_dmg, 0, max_recent_dmg)
	# Scale hitmarker by recent_damage
	for hitmarker in hitmarkers:
		hitmarker.scale.y = lerpf(hit_min_length, hit_max_length, recent_dmg / max_recent_dmg)
	# Play regular hitmarker animation
	anim_player.stop()
	anim_player.play(anim_name)
