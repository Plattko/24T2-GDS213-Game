class_name LANMultiplayerMenu
extends Control

@export_group("Switching Panels")
@export var host_panel_button : Button
@export var join_panel_button : Button
@export var host_panel : PanelContainer
@export var join_panel : PanelContainer

@export_group("Host Lobby")
@export var host_username_line : LineEdit
@export var create_button : Button

@export_group("Join Lobby")
@export var join_username_line : LineEdit
@export var ip_address_line : LineEdit
@export var join_button : Button

var host_username : String = ""
var join_username : String = ""

signal join_lobby_requested(lobby_id: int)
signal create_lobby_requested(lobby_name: String, is_private: bool, password: String)

func _ready() -> void:
	host_panel_button.toggled.connect(on_host_panel_button_toggled)
	join_panel_button.toggled.connect(on_join_panel_button_toggled)
	host_username_line.text_changed.connect(on_host_username_line_text_changed)
	join_username_line.text_changed.connect(on_join_username_line_text_changed)
	create_button.pressed.connect(on_create_button_pressed)
	join_button.pressed.connect(on_join_button_pressed)
	
	join_panel.hide()
	join_panel_button.button_pressed = false
	host_panel.show()
	host_panel_button.button_pressed = true

#-------------------------------------------------------------------------------
# Switching Panels
#-------------------------------------------------------------------------------
func on_host_panel_button_toggled(is_toggled: bool) -> void:
	# If the host panel button is already toggled on, do nothing
	if !is_toggled:
		host_panel_button.button_pressed = true
	# Otherwise, reset the host panel and switch to it
	else:
		join_panel_button.set_pressed_no_signal(false)
		join_panel.hide()
		host_username_line.text = ""
		create_button.disabled = true
		host_panel.show()

func on_join_panel_button_toggled(is_toggled: bool) -> void:
	# If the join panel button is already toggled on, do nothing
	if !is_toggled:
		join_panel_button.button_pressed = true
	# Otherwise, reset the join panel and switch to it
	else:
		host_panel_button.set_pressed_no_signal(false)
		host_panel.hide()
		join_username_line.text = ""
		ip_address_line.text = ""
		join_button.disabled = true
		join_panel.show()


#-------------------------------------------------------------------------------
# Hosting Lobby
#-------------------------------------------------------------------------------
func on_host_username_line_text_changed(new_text: String) -> void:
	if new_text == "":
		create_button.disabled = true
	else:
		create_button.disabled = false
	host_username = new_text

func on_create_button_pressed() -> void:
	# Set the lobby name to the text in the lobby name line
	var lobby_name = "%s's Lobby" % host_username
	# Request a lobby from the multiplayer connection menu
	create_lobby_requested.emit(lobby_name)

#-------------------------------------------------------------------------------
# Joining Lobby
#-------------------------------------------------------------------------------
func on_join_username_line_text_changed(new_text: String) -> void:
	if new_text == "":
		join_button.disabled = true
	else:
		join_button.disabled = false
	join_username = new_text

func get_server_ip(server_ip: String) -> String:
	if ip_address_line.text != "":
		print("Server IP: %s" % ip_address_line.text)
		return ip_address_line.text
	else:
		print("Server IP: %s" % server_ip)
		return server_ip

func on_join_button_pressed() -> void:
	join_lobby_requested.emit()
