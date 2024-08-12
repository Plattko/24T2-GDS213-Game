class_name LobbyDisplay
extends PanelContainer

@export var button : Button
@export var lobby_name_label : Label
@export var player_count_label : Label
@export var host_name_label : Label
@export var availability_label : Label

var lobby_name : String
var player_count : int
var host_name : String
var availability : String
var password : String

func _ready() -> void:
	lobby_name_label.text = lobby_name
	player_count_label.text = str(player_count) + "/4"
	host_name_label.text = host_name
	availability_label.text = availability
