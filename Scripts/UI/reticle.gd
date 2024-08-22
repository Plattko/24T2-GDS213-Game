class_name Reticle

extends CenterContainer

@export var lines : Array[Line2D] = []

@export var crosshair_colour : Color = Color.WHITE
@export var dot_radius := 1.0

@export_group("Circle", "circle")
@export var circle_radius := 65.0
@export var circle_width := 1.0

var cur_weapon : Weapon
var do_draw_dot : bool = true
var do_draw_circle : bool = false

func _ready():
	queue_redraw()

func _draw():
	if do_draw_dot:
		draw_circle(Vector2.ZERO, dot_radius, crosshair_colour)
	if do_draw_circle:
		draw_arc(Vector2.ZERO, circle_radius, 0, TAU, 100, crosshair_colour, circle_width, true)

func switch_to_line_crosshair() -> void:
	for line in lines:
		line.visible = true
	
	do_draw_dot = true
	do_draw_circle = false
	queue_redraw()

func switch_to_circle_crosshair() -> void:
	for line in lines:
		line.visible = false
	
	do_draw_dot = true
	do_draw_circle = true
	queue_redraw()

func update_reticle(weapon: Weapon) -> void:
	#print("Called update reticle.")
	cur_weapon = weapon
	if weapon is Rifle or weapon is Pistol or weapon is RocketLauncher:
		switch_to_line_crosshair()
	elif weapon is Shotgun or weapon is P90:
		switch_to_circle_crosshair()

func hide_reticle() -> void:
	for line in lines:
		line.hide()
	do_draw_dot = false
	do_draw_circle = false
	queue_redraw()

func show_reticle() -> void:
	update_reticle(cur_weapon)
