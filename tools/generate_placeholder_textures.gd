extends SceneTree
## Generates the small placeholder textures in res://textures/generated/.
## Run it from the project folder with:
##     godot --headless --path . -s tools/generate_placeholder_textures.gd
## (Running it again simply recreates the same images.)


const OUTPUT_FOLDER: String = "res://textures/generated"
const HAZARD_YELLOW := Color("ffc21a")
const HAZARD_BLACK := Color("1c1a22")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_FOLDER))
	var error := _hazard_stripes(32, 8).save_png(OUTPUT_FOLDER.path_join("hazard_stripes.png"))
	print("hazard_stripes.png: ", error_string(error))
	quit(0 if error == OK else 1)


## Diagonal yellow-and-black stripes that tile seamlessly (the image size must
## be a multiple of two stripe widths for the pattern to line up at the edges).
func _hazard_stripes(image_size: int, stripe_width: int) -> Image:
	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	for y in image_size:
		for x in image_size:
			var yellow := posmod(x + y, stripe_width * 2) < stripe_width
			image.set_pixel(x, y, HAZARD_YELLOW if yellow else HAZARD_BLACK)
	return image
