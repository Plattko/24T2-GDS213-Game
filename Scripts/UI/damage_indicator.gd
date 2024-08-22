class_name DamageIndicator
extends Control

var player : MultiplayerPlayer

var damage_indicator_texture := load("res://Assets/Textures/damage_indicator.png")
var indicator_array : Array[Dictionary]
var indicator_duration : int = 1
var indicator_lerp_speed : int = 18

func _physics_process(delta):
	if !is_multiplayer_authority(): return
	if indicator_array.is_empty(): return
	handle_indicators(delta)

func create_damage_indicator(target: Node) -> void:
	if player.is_downed: return
	if indicator_already_exists(target): return
	var texture_rect = TextureRect.new()
	texture_rect.texture = damage_indicator_texture
	texture_rect.pivot_offset = Vector2(175, 600)
	texture_rect.position = Vector2(-175, -600)
	texture_rect.modulate.a = 0.8
	add_child(texture_rect)
	var data = { 
		"elapsed_time" : 0.0,
		"node" : texture_rect, 
		"target" : target
		}
	indicator_array.append(data)

func indicator_already_exists(target: Node) -> bool:
	if not indicator_array.is_empty():
		for indicator in indicator_array:
			if indicator["target"] == target:
				indicator["elapsed_time"] = 0.0
				return true
	return false

func handle_indicators(delta: float) -> void:
	var index := 0
	for indicator in indicator_array:
		if !is_instance_valid(indicator["target"]):
			fade_out_indicator(indicator["node"])
			indicator_array.remove_at(index)
			break
		rotate_to_target(indicator["node"], indicator["target"], delta)
		indicator["elapsed_time"] += delta
		if indicator["elapsed_time"] >= indicator_duration:
			fade_out_indicator(indicator["node"])
			indicator_array.remove_at(index)
			break
		index += 1

func rotate_to_target(indicator: TextureRect, target: Node, delta: float) -> void:
	var player_pos = player.global_position
	var target_pos = target.global_position
	player_pos.y = 0
	target_pos.y = 0
	var dir = Vector3(player_pos - target_pos).normalized()
	var angle = dir.signed_angle_to(-player.transform.basis.z, Vector3.UP)
	indicator.rotation = lerp_angle(indicator.rotation, angle + PI, indicator_lerp_speed * delta)

func fade_out_indicator(indicator: TextureRect) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(indicator, "modulate:a", 0, 0.5)
	await tween.finished
	indicator.queue_free()
