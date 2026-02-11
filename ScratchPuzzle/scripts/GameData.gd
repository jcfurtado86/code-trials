# GameData.gd
extends Node

var last_completed_level: int = 0
var level_stars: Dictionary = {} # Exemplo: {"1": 2, "2": 3, "3": 1} - Chaves serão strings

func _ready():
	load_progress()

# A função save_progress do GameData agora recebe o level_to_save como int
# e o converte para string internamente para usar como chave.
func save_progress(level_to_save: int, stars_earned: int):
	# Converte o número do nível para string para usar como chave no dicionário
	var level_key = str(level_to_save)

	# Atualiza o progresso de níveis
	if level_to_save > last_completed_level:
		last_completed_level = level_to_save

	# Atualiza recorde de estrelas do nível usando a chave de string
	# Certifica-se de que stars_earned não é nulo antes de comparar
	if !level_stars.has(level_key) or (stars_earned != null and stars_earned > level_stars[level_key]):
		level_stars[level_key] = stars_earned
	elif stars_earned == null and !level_stars.has(level_key): # Caso stars_earned seja null e o nível ainda não tenha estrelas salvas
		level_stars[level_key] = 0 # Inicializa com 0 estrelas

	# Salva tudo em arquivo
	var save_file = FileAccess.open("user://game_progress.dat", FileAccess.WRITE)
	if save_file:
		var data = {
			"last_completed_level": last_completed_level,
			"level_stars": level_stars
		}
		save_file.store_line(JSON.stringify(data))
		save_file.close()
	else:
		print("GameData.gd: Erro ao abrir arquivo para salvar.")

func load_progress():
	if FileAccess.file_exists("user://game_progress.dat"):
		var save_file = FileAccess.open("user://game_progress.dat", FileAccess.READ)
		if save_file:
			var line = save_file.get_line()
			if line != "":
				var data = JSON.parse_string(line)
				if typeof(data) == TYPE_DICTIONARY:
					last_completed_level = data.get("last_completed_level", 0)
					var loaded_stars = data.get("level_stars", {})
					level_stars = {}
					for key in loaded_stars:
						level_stars[str(key)] = loaded_stars[key]
			save_file.close()
	else:
		print("GameData.gd: Nenhum progresso salvo encontrado.")
