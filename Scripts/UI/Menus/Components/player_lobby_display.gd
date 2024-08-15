class_name PlayerLobbyDisplay
extends PanelContainer

@export var name_label : Label
@export var ready_status_label : Label

var player_name : String = "Name"

func _ready() -> void:
	name_label.text = player_name

func update_ready_status_text(is_ready: bool) -> void:
	if is_ready: ready_status_label.text = "Ready"
	else: ready_status_label.text = "Not Ready"
