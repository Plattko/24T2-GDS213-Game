extends CharacterBody3D

@export var anim_player : AnimationPlayer
@export var fast_flash_timer : Timer
@export var deletion_timer : Timer

var health : float = 25.0

func _ready() -> void:
	anim_player.play("Idle")

func _physics_process(delta) -> void:
	if !is_on_floor():
		print("Not on floor")
		velocity.y -=  .0 * delta
		move_and_slide()
	else:
		anim_player.play("Idle")
		set_physics_process(false)

func _on_pickup_area_body_entered(body) -> void:
	if body is MultiplayerPlayer:
		if body.cur_health != body.max_health:
			body.on_healed(health)
			queue_free()

func _on_slow_flash_timer_timeout():
	anim_player.play("SlowFlash")
	fast_flash_timer.start()

func _on_fast_flash_timer_timeout():
	anim_player.play("FastFlash")
	deletion_timer.start()

func _on_lifetime_timer_timeout():
	queue_free()
