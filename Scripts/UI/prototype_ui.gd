extends MarginContainer

@export var progress_text : Label
@export var win_text : VBoxContainer
@export var time_text: Label

@export var reticle : CenterContainer
@export var ammo : MarginContainer
@export var instruction_text : Label

var destructible_orbs = []
var orbs_destroyed : int

var is_stopwatch_on : bool = true
var stopwatch_time : float = 0.0
var time_passed : String

func _ready():
	destructible_orbs = get_tree().get_nodes_in_group("destructible_orbs")
	set_orbs_text()
	for orb in destructible_orbs:
		orb.orb_destroyed.connect(update_orbs_text)

func _input(event):
	if event.is_action_pressed("restart") and win_text.visible == true:
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()

func _process(delta):
	if is_stopwatch_on:
		stopwatch_time += delta
	
	var mils = fmod(stopwatch_time, 1) * 1000
	var secs = fmod(stopwatch_time, 60)
	var mins = fmod(stopwatch_time, 60 * 60) / 60
	
	mils = int(mils) % 100
	
	time_passed = "%02d : %02d : %02d" % [mins, secs, mils]
	time_text.set_text("Time: " + time_passed)

func set_orbs_text():
	progress_text.set_text("Progress: " + "0/" + str(destructible_orbs.size()))

func update_orbs_text():
	orbs_destroyed += 1
	
	if orbs_destroyed < destructible_orbs.size():
		progress_text.set_text("Progress: " + str(orbs_destroyed) + "/" + str(destructible_orbs.size()))
	else:
		is_stopwatch_on = false
		reticle.visible = false
		ammo.visible = false
		instruction_text.visible = false
		progress_text.visible = false
		
		time_text.set_text("Time: " + time_passed)
		win_text.visible = true
		Engine.time_scale = 0.0
