class_name MapGenerator

# Referências a cenas
const PLAYER_SCENE = preload("res://actors/player.tscn")
const GOAL_SCENE = preload("res://scenes/goal.tscn")
const NEXT_LEVEL_MENU_SCENE = preload("res://scenes/next_level_menu.tscn")
const TRANSITION_SCENE = preload("res://scenes/transition.tscn")
const SPIKES_SCENE = preload("res://prefabs/spikes_area.tscn")
const MOVING_PLATFORM_SCENE = preload("res://prefabs/moving_platform.tscn")
const FALLING_PLATFORM_SCENE = preload("res://prefabs/falling_platform.tscn")
const BACKGROUND_TEXTURE = preload("res://assets/Free Industrial Zone Tileset/2 Background/Background.png")
const MAPS_SCRIPT = preload("res://scripts/maps.gd")

# Cenas de comando
const CMD_ANDAR = preload("res://commands/ComandoAndar.tscn")
const CMD_VIRAR = preload("res://commands/ComandoVirar.tscn")
const CMD_PULAR = preload("res://commands/ComandoPular.tscn")
const CMD_PARAR = preload("res://commands/ComandoParar.tscn")
const CMD_ESPERAR = preload("res://commands/ComandoEsperar.tscn")
const CMD_REPETIR = preload("res://commands/ComandoRepetir.tscn")
const CMD_SE = preload("res://commands/ComandoSe.tscn")

# TileSet reutilizado do level_1
static var _shared_tileset: TileSet = null

# Dimensões do mapa
const TILE_SIZE = 16
const MAP_HEIGHT = 20  # tiles de altura
const GROUND_Y = 11    # linha do chão (de cima)
const FILL_ROWS = 5    # linhas abaixo do chão para preencher

# Atlas coords para tiles (source_id = 1, main_tileset)
# Valores extraídos da análise do level_1.tscn tile_data
const TILE_SURFACE = Vector2i(2, 5)          # superfície da plataforma (caminhável)
const TILE_FILL_A = Vector2i(6, 10)          # preenchimento interno variante A
const TILE_FILL_B = Vector2i(6, 12)          # preenchimento interno variante B
const TILE_EDGE_LEFT = Vector2i(1, 2)        # borda esquerda
const TILE_EDGE_RIGHT = Vector2i(3, 2)       # borda direita
const TILE_CEIL_LEFT = Vector2i(1, 1)        # teto esquerda
const TILE_CEIL_MID = Vector2i(2, 1)         # teto meio
const TILE_CEIL_RIGHT = Vector2i(3, 1)       # teto direita

# Dificuldades
enum Difficulty { EASY, MEDIUM, HARD }

# Configuração por dificuldade
const MAP_WIDTH = 36  # tiles para caber no viewport (576 / 16)

const DIFFICULTY_CONFIG = {
	Difficulty.EASY: {
		"comandos": [CMD_ANDAR, CMD_VIRAR, CMD_PULAR, CMD_PARAR, CMD_ESPERAR, CMD_REPETIR, CMD_SE],
		"comando_requerido": "virar",
		"holes": 0,
		"spikes": 0,
		"elevations": 1,
		"floating_platforms": 0,
		"moving_platforms": 0,
		"falling_platforms": 0,
	},
	Difficulty.MEDIUM: {
		"comandos": [CMD_ANDAR, CMD_VIRAR, CMD_PULAR, CMD_PARAR, CMD_ESPERAR, CMD_REPETIR, CMD_SE],
		"comando_requerido": "pular",
		"holes": 1,
		"spikes": 1,
		"elevations": 2,
		"floating_platforms": 1,
		"moving_platforms": 1,
		"falling_platforms": 0,
	},
	Difficulty.HARD: {
		"comandos": [CMD_ANDAR, CMD_VIRAR, CMD_PULAR, CMD_PARAR, CMD_ESPERAR, CMD_REPETIR, CMD_SE],
		"comando_requerido": "se",
		"holes": 2,
		"spikes": 2,
		"elevations": 2,
		"floating_platforms": 2,
		"moving_platforms": 1,
		"falling_platforms": 1,
	},
}

static func _get_tileset() -> TileSet:
	if _shared_tileset:
		return _shared_tileset
	var level1_scene = load("res://levels/level_1.tscn")
	if not level1_scene:
		print("❌ Não conseguiu carregar level_1.tscn")
		return null
	var level1 = level1_scene.instantiate()
	var tilemap = level1.get_node_or_null("TileMap")
	if tilemap and tilemap.tile_set:
		_shared_tileset = tilemap.tile_set.duplicate()
		print("✅ TileSet carregado com sucesso")
	else:
		print("❌ TileMap ou TileSet não encontrado no level_1")
	level1.queue_free()
	return _shared_tileset

static func generate(difficulty: int, rng_seed: int = -1) -> Node2D:
	var rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	var config = DIFFICULTY_CONFIG[difficulty]
	var width: int = MAP_WIDTH

	# Tenta gerar um mapa solvável (máx 50 tentativas)
	var grid: Dictionary
	var attempts := 0
	while attempts < 50:
		grid = _generate_terrain(width, config, rng)
		if _is_solvable(grid, width):
			break
		attempts += 1
		# Muda a seed para tentar outro layout
		rng.seed = rng.randi()

	# Cria a cena do nível SEM script primeiro (adiciona filhos, depois seta script)
	var level = Node2D.new()
	level.name = "procedural_level"
	level.scale = Vector2(2.5, 2.5)

	# Background
	var bg = Sprite2D.new()
	bg.name = "Background"
	bg.texture = BACKGROUND_TEXTURE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	bg.position = Vector2(16, 3.2)
	bg.scale = Vector2(float(width) / 36.0, 1.0)
	bg.centered = false
	level.add_child(bg)

	# TileMap
	var tileset = _get_tileset()
	if tileset:
		var tilemap = TileMap.new()
		tilemap.name = "TileMap"
		tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tilemap.position = Vector2(0, 11.2)
		tilemap.tile_set = tileset
		level.add_child(tilemap)
		_paint_tilemap(tilemap, grid, width)

	# Posição Y do chão em pixels locais (tilemap offset + grid row * tile size)
	const TILEMAP_OFFSET_Y = 11.2
	var ground_pixel_y = TILEMAP_OFFSET_Y + GROUND_Y * TILE_SIZE

	# Player — fica em cima do chão (30px acima para compensar sprite)
	var player = PLAYER_SCENE.instantiate()
	player.name = "player"
	player.position = Vector2(2 * TILE_SIZE, ground_pixel_y - 14)
	level.add_child(player)

	# Goal — fica em cima do chão na posição do goal_y
	var goal = GOAL_SCENE.instantiate()
	goal.name = "goal"
	var goal_ground_y = TILEMAP_OFFSET_Y + grid["goal_y"] * TILE_SIZE
	goal.position = Vector2((width - 3) * TILE_SIZE, goal_ground_y - 19)
	goal.scale = Vector2(1.5, 1.5)
	level.add_child(goal)

	# Obstáculos
	_place_obstacles(level, grid, config, rng, width)

	# Next level menu
	var next_menu = NEXT_LEVEL_MENU_SCENE.instantiate()
	next_menu.name = "next_level_menu"
	next_menu.visible = false
	level.add_child(next_menu)

	# Transition
	var transition = TRANSITION_SCENE.instantiate()
	transition.name = "transition"
	transition.visible = false
	level.add_child(transition)

	# Seta o script DEPOIS de todos os filhos existirem
	# para que @onready funcione quando _ready() rodar
	level.set_script(MAPS_SCRIPT)
	level.set("nome", "infinito_%d" % rng.randi())
	var cmds: Array[PackedScene] = []
	for cmd in config["comandos"]:
		cmds.append(cmd)
	level.set("comandos", cmds)
	level.set("comando_requerido", config["comando_requerido"])
	level.set("max_comandos", int(width * 0.4))

	return level

# === Verificação de solvabilidade ===

static func _is_solvable(grid: Dictionary, width: int) -> bool:
	var columns: Array = grid["columns"]
	var floats: Array = grid.get("floating_platforms", [])

	# Monta mapa de alturas por coluna (inclui plataformas flutuantes)
	# Cada coluna pode ter múltiplas alturas válidas
	var heights_at: Dictionary = {}  # x -> Array de alturas
	for x in range(width):
		heights_at[x] = []
		if columns[x]["type"] != "hole":
			heights_at[x].append(columns[x]["height"])

	for plat in floats:
		for dx in range(plat["width"]):
			var px = plat["x"] + dx
			if px >= 0 and px < width:
				heights_at[px].append(plat["y"])

	var player_x := 2
	var player_y: int = columns[player_x]["height"]
	var goal_x := width - 3

	while player_x < goal_x:
		var advanced := false

		# Tenta andar 1 tile
		var next_x = player_x + 1
		if next_x < width:
			for h in heights_at[next_x]:
				var diff = player_y - h
				if diff >= 0 or abs(diff) <= 1:
					# Pode andar (mesmo nível ou descida ou subida de 1)
					player_x = next_x
					player_y = h
					advanced = true
					break

		if advanced:
			continue

		# Tenta pular (2 tiles frente, até 3 tiles acima)
		for dx in range(1, 3):
			var land_x = player_x + dx
			if land_x >= width:
				continue
			for h in heights_at[land_x]:
				var diff = player_y - h  # positivo = subir
				if diff <= 3 and diff >= -5:  # pode subir 3, descer 5
					player_x = land_x
					player_y = h
					advanced = true
					break
			if advanced:
				break

		if not advanced:
			return false

	return true


static func _generate_terrain(width: int, config: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	# Grid: array de colunas, cada coluna tem o tipo e a altura do chão
	var columns: Array = []
	var goal_y = GROUND_Y

	for x in range(width):
		columns.append({"type": "ground", "height": GROUND_Y})

	# Bordas seguras (primeiras e últimas 3 colunas são chão plano)
	var safe_start = 4
	var safe_end = width - 4

	# Coleta posições disponíveis para obstáculos
	var available_positions: Array = []
	for x in range(safe_start, safe_end):
		available_positions.append(x)
	# Shuffle manual usando o rng com seed para ser determinístico
	for i in range(available_positions.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var tmp = available_positions[i]
		available_positions[i] = available_positions[j]
		available_positions[j] = tmp

	var pos_index = 0

	# Elevações
	for _i in range(config["elevations"]):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		var elev_width = rng.randi_range(2, 4)
		var elev_height = rng.randi_range(2, 3)
		for dx in range(elev_width):
			var col_x = x + dx
			if col_x >= 0 and col_x < width and col_x >= safe_start and col_x < safe_end:
				columns[col_x]["type"] = "elevation"
				columns[col_x]["height"] = GROUND_Y - elev_height

	# Atualiza goal_y se o final tem elevação
	goal_y = columns[width - 3]["height"]

	# Buracos
	for _i in range(config["holes"]):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		var hole_width = rng.randi_range(1, 2)
		for dx in range(hole_width):
			var col_x = x + dx
			if col_x >= safe_start and col_x < safe_end:
				columns[col_x]["type"] = "hole"

	# Spikes (marcados para colocar depois)
	var spike_positions: Array = []
	for _i in range(config["spikes"]):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		spike_positions.append(x)
		columns[x]["type"] = "spike"

	# Plataformas flutuantes (segundo andar de tiles)
	var floating_platforms: Array = []  # [{x, width, y}]
	for _i in range(config.get("floating_platforms", 0)):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		var plat_width = rng.randi_range(3, 6)
		var plat_y = GROUND_Y - rng.randi_range(4, 6)  # 4-6 tiles acima do chão
		floating_platforms.append({"x": x, "width": plat_width, "y": plat_y})

	# Plataformas móveis (marcados para colocar depois)
	var moving_positions: Array = []
	for _i in range(config["moving_platforms"]):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		moving_positions.append(x)

	# Plataformas que caem
	var falling_positions: Array = []
	for _i in range(config["falling_platforms"]):
		if pos_index >= available_positions.size():
			break
		var x = available_positions[pos_index]
		pos_index += 1
		falling_positions.append(x)

	return {
		"columns": columns,
		"goal_y": goal_y,
		"spike_positions": spike_positions,
		"moving_positions": moving_positions,
		"falling_positions": falling_positions,
		"floating_platforms": floating_platforms,
	}

static func _paint_tilemap(tilemap: TileMap, grid: Dictionary, width: int) -> void:
	var columns: Array = grid["columns"]

	for x in range(width):
		var col = columns[x]

		if col["type"] == "hole":
			continue

		var ground_y = col["height"]

		# Superfície do chão (caminhável)
		tilemap.set_cell(0, Vector2i(x, ground_y), 1, TILE_SURFACE)

		# Preenchimento abaixo do chão
		for y in range(ground_y + 1, ground_y + FILL_ROWS + 1):
			var fill = TILE_FILL_A if (x + y) % 2 == 0 else TILE_FILL_B
			tilemap.set_cell(0, Vector2i(x, y), 1, fill)

		# Se é elevação, preencher entre o chão elevado e o chão normal
		if col["type"] == "elevation" and ground_y < GROUND_Y:
			for y in range(ground_y + 1, GROUND_Y):
				var fill = TILE_FILL_A if (x + y) % 2 == 0 else TILE_FILL_B
				tilemap.set_cell(0, Vector2i(x, y), 1, fill)
			tilemap.set_cell(0, Vector2i(x, GROUND_Y), 1, TILE_SURFACE)

	# Paredes laterais
	for y in range(-1, GROUND_Y + FILL_ROWS + 1):
		tilemap.set_cell(0, Vector2i(-1, y), 1, TILE_EDGE_LEFT)
		tilemap.set_cell(0, Vector2i(width, y), 1, TILE_EDGE_RIGHT)

	# Teto
	tilemap.set_cell(0, Vector2i(-1, -1), 1, TILE_CEIL_LEFT)
	for x in range(0, width):
		tilemap.set_cell(0, Vector2i(x, -1), 1, TILE_CEIL_MID)
	tilemap.set_cell(0, Vector2i(width, -1), 1, TILE_CEIL_RIGHT)

	# Plataformas flutuantes (segundo andar)
	for plat in grid.get("floating_platforms", []):
		var px: int = plat["x"]
		var py: int = plat["y"]
		var pw: int = plat["width"]
		for dx in range(pw):
			var tile_x = px + dx
			if tile_x >= 0 and tile_x < width:
				# Superfície da plataforma
				tilemap.set_cell(0, Vector2i(tile_x, py), 1, TILE_SURFACE)
				# 1 tile de preenchimento abaixo para dar corpo
				tilemap.set_cell(0, Vector2i(tile_x, py + 1), 1, TILE_FILL_A)

static func _place_obstacles(level: Node2D, grid: Dictionary, _config: Dictionary, rng: RandomNumberGenerator, _width: int) -> void:
	const OFS_Y = 11.2  # tilemap offset

	# Spikes — em cima do chão
	for x in grid["spike_positions"]:
		var spike = SPIKES_SCENE.instantiate()
		spike.name = "spikes_%d" % x
		var col_height = grid["columns"][x]["height"]
		spike.position = Vector2(x * TILE_SIZE, OFS_Y + col_height * TILE_SIZE - 6)
		spike.set("rect_w", TILE_SIZE * 2.0)
		level.add_child(spike)

	# Plataformas móveis — acima do chão
	for x in grid["moving_positions"]:
		var platform = MOVING_PLATFORM_SCENE.instantiate()
		platform.name = "moving_%d" % x
		var col_height = grid["columns"][x]["height"]
		platform.position = Vector2(x * TILE_SIZE, OFS_Y + (col_height - 5) * TILE_SIZE)
		platform.set("distance", TILE_SIZE * rng.randi_range(3, 6))
		platform.set("move_speed", rng.randf_range(2.0, 4.0))
		platform.set("move_horizonal", true)
		level.add_child(platform)

	# Plataformas que caem — na altura do chão
	for x in grid["falling_positions"]:
		var platform = FALLING_PLATFORM_SCENE.instantiate()
		platform.name = "falling_%d" % x
		var col_height = grid["columns"][x]["height"]
		platform.position = Vector2(x * TILE_SIZE, OFS_Y + (col_height - 2) * TILE_SIZE)
		level.add_child(platform)
