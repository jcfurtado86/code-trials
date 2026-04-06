extends PanelContainer

const MapGenerator = preload("res://scripts/map_generator.gd")

@onready var execute_area: PanelContainer = $MarginContainer/LeftColumn/ExecuteArea
@onready var v_box_container: VBoxContainer = $MarginContainer/LeftColumn/ExecuteArea/MarginContainer/VBoxContainer/TabContainer/Blocos/ScrollContainer/VBoxContainer
@onready var tab_container: TabContainer = $MarginContainer/LeftColumn/ExecuteArea/MarginContainer/VBoxContainer/TabContainer
@onready var code_edit: CodeEdit = $MarginContainer/LeftColumn/ExecuteArea/MarginContainer/VBoxContainer/TabContainer/Codigo/CodeEdit
@onready var map_container: Node = $LevelArea
@onready var command_container: Node = $MarginContainer/LeftColumn/CommandArea/MarginContainer/VBoxContainer/GridContainer
@onready var clear_button: Button = $MarginContainer/LeftColumn/ExecuteArea/MarginContainer/VBoxContainer/HBoxContainer/ClearButton
@onready var execute_button = $MarginContainer/LeftColumn/ExecuteArea/MarginContainer/VBoxContainer/HBoxContainer/ExecuteButton
@onready var star_icons := [
	$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer/Star,
	$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer2/Star,
	$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer3/Star
]
@export var star_texture: Texture2D
@export var gray_star_texture: Texture2D


@export var maps: Dictionary = {
	"level_1": preload("res://levels/level_1.tscn"),
	"level_2": preload("res://levels/level_2.tscn"),
	"level_3": preload("res://levels/level_3.tscn"),
	"level_4": preload("res://levels/level_4.tscn"),
	"level_5": preload("res://levels/level_5.tscn"),
	"level_6": preload("res://levels/level_6.tscn"),
	"level_7": preload("res://levels/level_7.tscn"),
	"level_8": preload("res://levels/level_8.tscn")
}

var current_map = null
@export var current_level = "level_1"
var player = null
var is_training_mode := false
var training_difficulty: int = MapGenerator.Difficulty.EASY
var _current_seed: int = -1

func _ready():
	add_to_group("MainNode")
	if clear_button and not clear_button.pressed.is_connected(_on_clear_button_pressed):
		clear_button.pressed.connect(_on_clear_button_pressed)

	if is_training_mode:
		call_deferred("load_procedural")
	else:
		load_level(current_level)

func start_training(difficulty: int) -> void:
	is_training_mode = true
	training_difficulty = difficulty
	load_procedural()

func load_procedural(new_map := true) -> void:
	if execute_area.has_method("prepare_for_scene_change"):
		execute_area.prepare_for_scene_change()

	_on_clear_button_pressed()

	execute_button.disabled = false
	if current_map:
		current_map.queue_free()

	if new_map:
		_current_seed = randi()
	current_map = MapGenerator.generate(training_difficulty, _current_seed)
	if not current_map:
		print("❌ Falha ao gerar mapa!")
		return
	print("✅ Mapa gerado: ", current_map.name, " filhos: ", current_map.get_child_count())
	current_map.main_node = self
	map_container.add_child(current_map)
	print("✅ Mapa adicionado ao container, player: ", current_map.get_node_or_null("player"))
	_scale_map_to_container()

	player = current_map.get_node("player")
	if player and not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

	load_commands()
	update_level_info("treino_0")

	if execute_area.has_method("scene_change_completed"):
		execute_area.scene_change_completed()
	if execute_area.has_method("find_map_and_player"):
		execute_area.find_map_and_player()

	current_map.process_mode = ProcessMode.PROCESS_MODE_INHERIT

func load_level(level_name: String):
	if execute_area.has_method("prepare_for_scene_change"):
		execute_area.prepare_for_scene_change()
	
	_on_clear_button_pressed()
	load_map(level_name)
	update_level_info(level_name)
	
	if execute_area.has_method("scene_change_completed"):
		execute_area.scene_change_completed()

func load_map(level_name: String):
	execute_button.disabled = false
	if current_map:
		current_map.queue_free()

	if level_name in maps:
		current_map = maps[level_name].instantiate()
		current_map.main_node = self
		map_container.add_child(current_map)
		_scale_map_to_container()

		player = current_map.get_node("player")
		if player:
			if not player.player_died.is_connected(_on_player_died):
				player.player_died.connect(_on_player_died)
		else:
			print("Player não encontrado no mapa!")
		load_commands()

const NATIVE_MAP_SIZE = Vector2(576, 324)

func _scale_map_to_container() -> void:
	if not current_map or not map_container:
		return
	await get_tree().process_frame
	var container_size = map_container.size
	var scale_factor = min(container_size.x / NATIVE_MAP_SIZE.x, container_size.y / NATIVE_MAP_SIZE.y)
	current_map.scale = Vector2(scale_factor, scale_factor)

func load_commands():
	for child in command_container.get_children():
		child.queue_free()
	
	if current_map and "comandos" in current_map:
		for command_scene in current_map.comandos:
			if command_scene:
				var command_instance = command_scene.instantiate()
				command_container.add_child(command_instance)

func update_level_info(level_name: String):
	$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/LevelTitle.text = "LEVEL - " + level_name.split("_")[1]
	
	if current_map and "stars" in current_map:
		var level_stars = current_map.stars
		
		if level_stars.size() == 3:
			$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer/Label.text = level_stars[0]  # Atualiza a primeira estrela
			$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer2/Label.text = level_stars[1]  # Atualiza a segunda estrela
			$MarginContainer/LevelInfo/MarginContainer/VBoxContainer/HBoxContainer3/Label.text = level_stars[2]  # Atualiza a terceira estrela
		
			resetar_estrelas()

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

func _on_player_died():
	resetar_estrelas()
	if is_training_mode:
		load_procedural(false)
	else:
		load_map(current_map.nome)

func _on_restart_button_pressed() -> void:
	if is_training_mode:
		resetar_estrelas()
		load_procedural(false)
	else:
		if current_map and current_map.has_method("resetar_objetivos"):
			current_map.resetar_objetivos()
		load_map(current_map.nome)
		resetar_estrelas()

func _on_clear_button_pressed() -> void:

	if execute_area.has_method("safe_clear"):
		execute_area.safe_clear()
		await get_tree().process_frame
		execute_area.setup_drop_indicator()
	else:
		for child in execute_area.get_children():
			child.queue_free()
		await get_tree().process_frame
		execute_area.setup_drop_indicator()

func _on_execute_button_pressed() -> void:
	current_map.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	
	var total_comando := 0
	if tab_container.current_tab == 0:
		total_comando = count_children_recursively(v_box_container)
	else:
		var result = CodeParser.parse(code_edit.text)
		if result.success:
			total_comando = result.command_count

	if current_map and current_map.has_method("set_total_comandos"):
		current_map.set_total_comandos(total_comando)

func count_children_recursively(node: Node) -> int:
	var total = 0
	
	for child in node.get_children():
		if child is TextureRect:
			total += 1

		for grandchild in child.get_children():
			if grandchild is VBoxContainer:
				total += count_children_recursively(grandchild)
		
	return total
