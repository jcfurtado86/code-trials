extends CanvasLayer

@onready var resume_button: Button = $menu_holder/ResumeButton

##############################################################
@onready var star_icons := [
	$menu_holder/HBoxContainer/Star,
	$menu_holder/HBoxContainer/Star2,
	$menu_holder/HBoxContainer/Star3
]
@export var star_texture: Texture2D
@export var gray_star_texture: Texture2D

func atualizar_estrelas(objetivos: Array):
	for i in range(star_icons.size()):
		if i < objetivos.size():
			if objetivos[i]:
				star_icons[i].texture = star_texture
			else:
				star_icons[i].texture = gray_star_texture

func resetar_estrelas():
	for star in star_icons:
		star.texture = gray_star_texture

#################################################################################

func _ready() -> void:
	visible = false
	resetar_estrelas()

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event) -> void:
	if event.is_action_pressed('ui_cancel'):
		visible = true
		get_tree().paused = true
		resume_button.grab_focus()

func _on_resume_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_button()
	get_tree().paused = false
	visible = false

func _on_quit_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_button()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
