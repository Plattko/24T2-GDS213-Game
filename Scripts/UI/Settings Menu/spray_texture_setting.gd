class_name SprayTextureSetting
extends Control

@export var replace_texture_button : Button
@export var spray_texture_display : TextureRect
@export var file_dialog : FileDialog

#var default_spray_image : Image = load("res://Assets/Textures/default_spray_texture.png")

func _ready() -> void:
	replace_texture_button.pressed.connect(on_replace_texture_button_pressed)
	file_dialog.file_selected.connect(on_file_dialog_file_selected)
	
	#var default_texture = ImageTexture.create_from_image(default_spray_image)
	#update_spray_texture(default_texture)

func on_replace_texture_button_pressed() -> void:
	file_dialog.popup()

func on_file_dialog_file_selected(path: String) -> void:
	if is_image_file_format(path):
		# Create an image using the selected file
		var image = Image.new()
		image.load(path)
		# Create an image texture with the image
		var image_texture = ImageTexture.new()
		image_texture.set_image(image)
		# Update the spray texture in the Game Manager
		update_spray_texture(image_texture)
		# Display the image texture in the spray texture display
		spray_texture_display.texture = image_texture

func update_spray_texture(texture: ImageTexture) -> void:
	GameManager.spray_texture = texture
	#print("Game Manager spray texture: " + str(GameManager.spray_texture))

func is_image_file_format(path: String) -> bool:
	if path.ends_with(".png"): return true
	if path.ends_with(".PNG"): return true
	if path.ends_with(".jpeg"): return true
	if path.ends_with(".JPEG"): return true
	if path.ends_with(".jpg"): return true
	if path.ends_with(".JPG"): return true
	return false
