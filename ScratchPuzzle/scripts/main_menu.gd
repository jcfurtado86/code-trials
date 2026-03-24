extends Control
class_name MainMenu

func _ready() -> void:
	for _button in get_tree().get_nodes_in_group("button"):
		_button.pressed.connect(_on_button_pressed.bind(_button))

func _on_button_pressed(_button: Button) -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_button()
	match _button.name:
		"PlayButton":
			get_tree().change_scene_to_file("res://scenes/level_select_menu.tscn")
		"CreditsButton":
			get_tree().change_scene_to_file("res://scenes/credits.tscn")
		"QuitButton":
			get_tree().quit()
