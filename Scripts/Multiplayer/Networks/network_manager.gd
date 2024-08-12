class_name NetworkManager
extends Node

#var multiplayer_manager : MultiplayerManager
var multiplayer_connection_menu : MultiplayerConnectionMenu

enum Multiplayer_Network_Type { ENET, STEAM, }
var active_network_type : Multiplayer_Network_Type = Multiplayer_Network_Type.ENET

var enet_network_scene = load("res://Scenes/Multiplayer/Networks/enet_network.tscn")
var steam_network_scene = load("res://Scenes/Multiplayer/Networks/steam_network.tscn")
var active_network

func build_multiplayer_network() -> void:
	# Only do this if we don't have an active network
	if not active_network:
		print("Setting active network.")
		
		match active_network_type:
			Multiplayer_Network_Type.ENET:
				print("Setting network type to ENet.")
				set_active_network(enet_network_scene)
			Multiplayer_Network_Type.STEAM:
				print("Setting network type to Steam.")
				set_active_network(steam_network_scene)
			_:
				print("No matching network type!")

func set_active_network(active_network_scene):
	active_network = active_network_scene.instantiate()
	#active_network.multiplayer_manager = multiplayer_manager
	active_network.multiplayer_connection_menu = multiplayer_connection_menu
	add_child(active_network)

func become_host(lobby_name: String, is_private: bool = false, password: String = "") -> void:
	build_multiplayer_network()
	active_network.become_host(lobby_name, is_private, password)

func join_as_client(lobby_id: int = 0) -> void:
	build_multiplayer_network()
	active_network.join_as_client(lobby_id)

func list_lobbies() -> void:
	build_multiplayer_network()
	active_network.list_lobbies()
