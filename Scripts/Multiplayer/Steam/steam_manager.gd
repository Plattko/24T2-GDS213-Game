extends Node

var is_owned : bool = false
var steam_app_id : int = 480 # Steam's test game app ID
var steam_id : int = 0
var steam_username : String = ""

var lobby_id : int = 0

func _init() -> void:
	print("Initialising Steam Manager.")
	# Set the game's Steam app ID
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _process(_delta) -> void:
	Steam.run_callbacks()

func initialise_steam() -> void:
	# Check if Steam initialised correctly
	var initialise_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialise? " + str(initialise_response))
	
	# Verify whether it did or not
	# Anything other than 0 is a problem
	if initialise_response['status'] > 0:
		print_debug("Failed to initialise Steam! Shutting down. " + str(initialise_response))
		# Quit the game if initialisation failed
		get_tree().quit()
	
	# If this code is reached, we are correctly initialised
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	print("Steam ID: " + str(steam_id))
	
	if !is_owned:
		print("User does not own the game.")
		# Could quit the game here
		# But we won't
