extends PanelContainer
@onready var texture_button: TextureButton = $HBoxContainer/TextureButton
@onready var texture_button_2: TextureButton = $HBoxContainer/TextureButton2
@onready var pause_menu: CanvasLayer = $"../../pause_menu"
@onready var tutorial: Control = $"../../CanvasLayer/Control"

func _on_texture_button_pressed() -> void:
	pause_menu.visible = true
	get_tree().paused = true

func _on_texture_button_2_pressed() -> void:
	if tutorial:
		tutorial.restart_tutorial()
