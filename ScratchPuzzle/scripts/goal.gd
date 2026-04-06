extends Area2D


@onready var goal: Area2D = self
@onready var next_level_menu: CanvasLayer = $"../next_level_menu"

@onready var player: CharacterBody2D = $"../player"



func _on_body_entered(body: Node2D) -> void:
	if body.name == 'player':
		player.parar()
		if is_instance_valid(SoundManager):
			SoundManager.play_won()

		var level = get_parent()
		if level.has_method("concluir_objetivo_computador"):
			level.concluir_objetivo_computador()

		await get_tree().create_timer(0.5).timeout

		# Verifica se está no modo treino
		var main_node = level.get("main_node")
		if main_node and main_node.get("is_training_mode"):
			# Gera próximo mapa procedural
			main_node.load_procedural()
		else:
			next_level_menu.visible = true

	else:
		print("No Scene Loaded")
