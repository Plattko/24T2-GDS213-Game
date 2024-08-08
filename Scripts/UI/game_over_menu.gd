class_name GameOverMenu
extends Control

@export var waves_survived_text : Label
@export var robots_killed_text : Label
@export var zone_swaps_text : Label

var waves_survived : int
var robots_killed : int
var zone_swaps : int

func _ready() -> void:
	waves_survived_text.text = "Waves Survived: " + str(waves_survived)
	robots_killed_text.text = "Robots Killed: " + str(robots_killed)
	zone_swaps_text.text = "Zone Swaps: " + str(zone_swaps)
