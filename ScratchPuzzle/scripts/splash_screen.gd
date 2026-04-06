extends Control

@onready var serde = $CenterContainer/HBoxContainer/Serde
@onready var ccc = $CenterContainer/HBoxContainer/CCC
@onready var unifap = $CenterContainer/HBoxContainer/Unifap

func _ready():
	# Fade in das logos uma por uma
	var tween = create_tween()

	# Serde aparece
	tween.tween_property(serde, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)

	# CCC aparece
	tween.tween_property(ccc, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)

	# UNIFAP aparece
	tween.tween_property(unifap, "modulate:a", 1.0, 0.6)

	# Espera 2 segundos mostrando todas
	tween.tween_interval(2.0)

	# Fade out de todas juntas
	tween.tween_property(serde, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(ccc, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(unifap, "modulate:a", 0.0, 0.5)

	tween.tween_interval(0.3)

	# Vai pro menu principal
	tween.tween_callback(_go_to_menu)

func _go_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event):
	# Pular splash ao clicar ou apertar qualquer tecla
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
