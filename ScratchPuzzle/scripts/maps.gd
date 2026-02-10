extends Node2D

@onready var next_level_menu: CanvasLayer = $next_level_menu
@onready var pause_menu: CanvasLayer = $pause_menu

@export var nome : String = ""
@export var comandos: Array[PackedScene] = []
@export var stars: Array[String] = ["ACESSE O COMPUTADOR", "", ""]

# Objetivos configuráveis
@export var comando_requerido: String = "andar"  # Comando específico para estrela 2
@export var max_comandos: int = 1                # Máximo de comandos para estrela 3

var total_comandos_usados := 0
var comandos_usados := []
var main_node = null
var level_number: int = 0

# Variáveis para rastrear objetivos
var objetivos_concluidos := [false, false, false]  # Computador, Comando Específico, Máx Comandos

func _ready():
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	stars[1] = "USE O COMANDO " + comando_requerido.to_upper()
	stars[2] = "USE NO MÁXIMO %d COMANDOS" % max_comandos
	resetar_objetivos()
	
	var parts = nome.split("_")
	if parts.size() == 2 and parts[0] == "level":
		level_number = int(parts[1])

func resetar_objetivos():
	objetivos_concluidos = [false, false, false]

# Chamado quando o jogador alcança o computador
func concluir_objetivo_computador():
	objetivos_concluidos[0] = true
	atualizar_ui_objetivos()
	
	# Conta quantas estrelas o jogador ganhou nesse level
	var stars_earned = objetivos_concluidos.count(true)

	# Salvar progresso global (nível e estrelas)
	if GameData.has_method("save_progress"):
		GameData.save_progress(level_number, stars_earned)
	else:
		print("Erro: 'GameData' não possui o método 'save_progress'.")


# Chamado quando um comando é executado
func registrar_comando(nome_comando: String):
	if nome_comando == comando_requerido:
		objetivos_concluidos[1] = true
	
	comandos_usados.append(nome_comando)
	atualizar_ui_objetivos()

func set_total_comandos(total_comandos: int):
	# Verifica o objetivo de limite de comandos
	objetivos_concluidos[2] = (total_comandos <= max_comandos)
	atualizar_ui_objetivos()

func atualizar_ui_objetivos():
	if main_node.has_method("atualizar_estrelas"):
		main_node.atualizar_estrelas(objetivos_concluidos)

	if pause_menu.has_method("atualizar_estrelas"):
		pause_menu.atualizar_estrelas(objetivos_concluidos)

	if next_level_menu.has_method("atualizar_estrelas"):
		next_level_menu.atualizar_estrelas(objetivos_concluidos)
