extends Node2D

@onready var next_level_menu: CanvasLayer = $next_level_menu
@onready var pause_menu: CanvasLayer = $pause_menu

@export var nome : String = ""
@export var comandos: Array[PackedScene] = []
@export var stars: Array[String] = ["ACESSE O COMPUTADOR", "", ""]
@export var comando_requerido: String = "andar"
@export var max_comandos: int = 1 
@export var tutorial_path: NodePath = "../../CanvasLayer/Control"

const TutorialStep = preload("res://scripts/tutorial_steps.gd").TutorialStep

var total_comandos_usados := 0
var comandos_usados := []
var main_node = null
var level_number: int = 0

var objetivos_concluidos := [false, false, false]

func _ready():
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	stars[1] = "USE O COMANDO " + comando_requerido.to_upper()
	stars[2] = "USE NO MÁXIMO %d COMANDOS" % max_comandos
	resetar_objetivos()
	_definir_numero_do_level()
	_configurar_tutorial()

func _configurar_tutorial() -> void:
	var tutorial = _get_tutorial()
	if tutorial == null:
		return

	if level_number == 1:
		tutorial.setup_tutorial(
			[
				TutorialStep.OBJECTIVES,
				TutorialStep.COMMANDS_AREA,
				TutorialStep.COMMANDS_BLOCK,
				TutorialStep.EXECUTION
			],
			_get_command_block_text()
		)
	else:
		tutorial.setup_tutorial(
			[ TutorialStep.COMMANDS_BLOCK ],
			_get_command_block_text()
		)

func _get_tutorial():
	return get_node_or_null(tutorial_path)

func _get_command_block_text() -> String:
	match comando_requerido:
		"andar":
			return "Este é o comando ANDAR.\nAo executar, o personagem anda continuamente para frente até receber outro comando."
		"virar":
			return "Este é o comando VIRAR.\nEle altera a direção do personagem sem movê-lo."
		"repetir":
			return "Este é o comando REPETIR.\nEle executa os comandos internos várias vezes."
		_:
			return "Este é um comando especial.\nUse-o para controlar o personagem."


func _definir_numero_do_level():
	var parts = nome.split("_")
	if parts.size() == 2 and parts[0] == "level":
		level_number = int(parts[1])

func resetar_objetivos():
	objetivos_concluidos = [false, false, false]

func concluir_objetivo_computador():
	objetivos_concluidos[0] = true
	atualizar_ui_objetivos()

	var stars_earned = objetivos_concluidos.count(true)

	if GameData.has_method("save_progress"):
		GameData.save_progress(level_number, stars_earned)
	else:
		print("Erro: 'GameData' não possui o método 'save_progress'.")

func registrar_comando(nome_comando: String):
	if nome_comando == comando_requerido:
		objetivos_concluidos[1] = true
	
	comandos_usados.append(nome_comando)
	atualizar_ui_objetivos()

func set_total_comandos(total_comandos: int):
	objetivos_concluidos[2] = (total_comandos <= max_comandos)
	atualizar_ui_objetivos()

func atualizar_ui_objetivos():
	if main_node.has_method("atualizar_estrelas"):
		main_node.atualizar_estrelas(objetivos_concluidos)

	if pause_menu.has_method("atualizar_estrelas"):
		pause_menu.atualizar_estrelas(objetivos_concluidos)

	if next_level_menu.has_method("atualizar_estrelas"):
		next_level_menu.atualizar_estrelas(objetivos_concluidos)
