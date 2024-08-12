class_name PlayerLobbyDisplay
extends PanelContainer

@export var name_label : Label
@export var ready_status_label : Label

var player_name : String

func _ready() -> void:
	name_label.text = player_name
