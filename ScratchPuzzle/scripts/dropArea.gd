extends PanelContainer

const COMMAND_NAMES = ["andar", "virar", "pular", "parar", "esperar", "repetir", "se"]
@onready var target_node = $MarginContainer/VBoxContainer/TabContainer/Blocos/ScrollContainer/VBoxContainer
@onready var level_area: Node = $"../../LevelArea"
@onready var tab_container: TabContainer = $MarginContainer/VBoxContainer/TabContainer
@onready var code_edit: CodeEdit = $MarginContainer/VBoxContainer/TabContainer/Codigo/CodeEdit
@onready var error_label: Label = $MarginContainer/VBoxContainer/ErrorLabel
var map: Node = null
var player: Node = null
var goal: Area2D = null
@onready var execute_button = $MarginContainer/VBoxContainer/HBoxContainer/ExecuteButton

# Variáveis para controle do drag and drop
var drag_preview : Control = null
var drop_indicator : ColorRect = null
var dragging_node : Control = null
var is_changing_level := false
var is_transitioning := false
var _exec_step := 0
var _exec_total := 0

const COMMAND_DESCRIPTIONS = {
	"andar": "Personagem anda para frente",
	"virar": "Altera a direção do personagem",
	"pular": "Personagem pula na direção atual",
	"parar": "Interrompe o movimento",
	"esperar": "Pausa por N segundos. Ex: esperar(2.0);",
	"repetir": "Repete N vezes. Ex: repetir(3) { andar(); }",
	"se": "Executa se condição for verdadeira. Ex: se(obstaculo_a_frente) { pular(); }",
}

const CONDITION_DESCRIPTIONS = {
	"no_chao": "Está no chão?",
	"obstaculo_a_frente": "Há obstáculo à frente?",
	"virado_direita": "Está virado para direita?",
	"virado_esquerda": "Está virado para esquerda?",
	"buraco_a_frente": "Há um buraco à frente?",
}

func _ready():
	add_to_group("execution_areas")
	await get_tree().process_frame
	find_map_and_player()
	setup_drop_indicator()
	_setup_code_edit()

func setup_drop_indicator():
	# Remove o indicador antigo se existir
	if drop_indicator and is_instance_valid(drop_indicator):
		target_node.remove_child(drop_indicator)
		drop_indicator.queue_free()
	
	# Cria um novo indicador
	drop_indicator = ColorRect.new()
	drop_indicator.color = Color(1, 1, 1, 0.5)
	drop_indicator.size = Vector2(0, 4)
	drop_indicator.visible = false
	target_node.add_child(drop_indicator)

func find_map_and_player():
	if level_area and level_area.get_child_count() > 0:
		map = level_area.get_child(0)
	
	if map:
		player = map.find_child("player", true, false)
	
	if not player:
		print("⚠️ Player não encontrado no mapa!")

func prepare_for_scene_change():
	is_transitioning = true
	# Limpa a área de forma segura
	safe_clear()

func scene_change_completed():
	is_transitioning = false
	# Reconfigura o sistema de drop
	setup_drop_indicator()

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return not is_transitioning and not is_changing_level

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if is_transitioning or is_changing_level or not is_instance_valid(drop_indicator):
		return

	var dropped_node = data[0]
	var original_parent = dropped_node.get_parent()
	
	drop_indicator.visible = false
	
	# Caso 1: Veio da área de comandos (duplica)
	if original_parent == $"../CommandArea/MarginContainer/VBoxContainer/GridContainer":
		var new_node = dropped_node.duplicate()
		var insert_position = calculate_insert_position(at_position, null)
		target_node.add_child(new_node)
		if insert_position < target_node.get_child_count() - 1:
			target_node.move_child(new_node, insert_position)
	
	# Caso 2: Já está na área de execução (reordena)
	elif original_parent == target_node:
		var insert_position = calculate_insert_position(at_position, dropped_node)
		target_node.remove_child(dropped_node)
		target_node.add_child(dropped_node)
		target_node.move_child(dropped_node, insert_position)
	
	# Caso 3: Veio de outro lugar (como o "SE") - move sem duplicar
	else:
		original_parent.remove_child(dropped_node)
		var insert_position = calculate_insert_position(at_position, null)
		target_node.add_child(dropped_node)
		if insert_position < target_node.get_child_count() - 1:
			target_node.move_child(dropped_node, insert_position)

	_update_block_numbers()

func calculate_insert_position(_at_position: Vector2, excluded_node: Control) -> int:
	var local_pos = target_node.get_local_mouse_position()
	var insert_position = target_node.get_child_count()
	
	for i in range(target_node.get_child_count()):
		var child = target_node.get_child(i)
		if child == excluded_node or child == drop_indicator:
			continue
			
		var child_rect = Rect2(Vector2(0, 0), child.size)
		child_rect.position = child.position
		
		# Verifica se a posição está acima do centro do filho atual
		if local_pos.y < child_rect.position.y + child_rect.size.y / 2:
			insert_position = i
			break
	
	return insert_position

func _get_drag_data(at_position: Vector2):
	if is_changing_level:
		return null
		
	# Identifica qual nó está sendo arrastado
	for child in target_node.get_children():
		if child == drop_indicator:
			continue
			
		var rect = Rect2(child.position, child.size)
		if rect.has_point(at_position):
			dragging_node = child
			
			# Cria um preview para feedback visual
			drag_preview = child.duplicate()
			drag_preview.modulate = Color(1, 1, 1, 0.7)
			set_drag_preview(drag_preview)
			
			return [child]
	return null

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		dragging_node = null
		if is_instance_valid(drop_indicator):
			drop_indicator.visible = false
		call_deferred("_update_block_numbers")

func _gui_input(event: InputEvent) -> void:
	# Duplo clique em um bloco para deletar
	if event is InputEventMouseButton and event.pressed and event.double_click:
		var local_pos = target_node.get_local_mouse_position()
		for child in target_node.get_children():
			if child == drop_indicator:
				continue
			if child is TextureRect:
				var rect = Rect2(child.position, child.size)
				if rect.has_point(local_pos):
					child.queue_free()
					call_deferred("_update_block_numbers")
					break

func _process(_delta):
	if is_changing_level:
		return
		
	if dragging_node and drag_preview and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var local_pos = target_node.get_local_mouse_position()
		var insert_pos = calculate_insert_position(local_pos, dragging_node)
		
		# Atualiza o indicador de drop
		if is_instance_valid(drop_indicator):
			if insert_pos < target_node.get_child_count():
				var reference_child = target_node.get_child(insert_pos)
				if reference_child != drop_indicator:
					drop_indicator.size = Vector2(target_node.size.x, 4)
					drop_indicator.position = reference_child.position - Vector2(0, 2)
					drop_indicator.visible = true
			else:
				var last_child = target_node.get_child(target_node.get_child_count() - 1)
				if last_child != drop_indicator:
					drop_indicator.size = Vector2(target_node.size.x, 4)
					drop_indicator.position = last_child.position + Vector2(0, last_child.size.y - 2)
					drop_indicator.visible = true

func safe_clear():
	is_changing_level = true
	# Limpa todos os comandos (blocos)
	for child in target_node.get_children():
		child.queue_free()
	# Limpa o código
	if code_edit:
		code_edit.text = ""
	is_changing_level = false

	# Recria completamente o sistema de drop
	setup_drop_indicator()
	# Garante que o drag and drop será reiniciado
	dragging_node = null
	drag_preview = null

func _on_execute_button_pressed() -> void:
	if is_changing_level:
		return

	execute_button.disabled = true
	_clear_error()

	var comandos = []

	if tab_container.current_tab == 0:
		# Modo blocos
		comandos = _parse_from_blocks()
	else:
		# Modo código
		var available = _get_available_command_names()
		var result = CodeParser.parse(code_edit.text, available)
		if not result.success:
			_show_code_error(result.error_message, result.error_line)
			execute_button.disabled = false
			return
		comandos = result.comandos

	await executar_sequencial(comandos)
	_clear_execution_feedback()

func _parse_from_blocks() -> Array:
	var comandos = []
	for child in target_node.get_children():
		if child == drop_indicator:
			continue
		if child is TextureRect and child.has_method("get_command_type"):
			var command_type = child.get_command_type()
			if command_type == 4:
				var tempo = child.get_valor() if child.has_method("get_valor") else 1.0
				comandos.append([child, tempo])
			elif command_type == 5:
				comandos.append([child, child.get_repeat_count(), child.get_comandos()])
			elif command_type == 6:
				comandos.append([child, child.get_condition()])
			else:
				comandos.append([child])
	return comandos

func _get_available_command_names() -> Array:
	var names: Array = []
	var command_area = $"../CommandArea/MarginContainer/VBoxContainer/GridContainer"
	for child in command_area.get_children():
		if child.has_method("get_command_type"):
			var cmd_type = child.get_command_type()
			if cmd_type >= 0 and cmd_type < COMMAND_NAMES.size():
				names.append(COMMAND_NAMES[cmd_type])
	return names

func _show_code_error(message: String, line: int) -> void:
	if error_label:
		error_label.text = "Linha %d: %s" % [line, message]
		error_label.visible = true
	if code_edit and line > 0:
		code_edit.set_caret_line(line - 1)

func _clear_error() -> void:
	if error_label:
		error_label.visible = false

# === Autocomplete ===

func _setup_code_edit() -> void:
	if not code_edit:
		print("⚠️ CodeEdit não encontrado!")
		return
	print("✅ CodeEdit configurado para autocomplete")
	code_edit.code_completion_enabled = true
	code_edit.code_completion_prefixes = PackedStringArray(["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","("])
	code_edit.code_completion_requested.connect(_on_code_completion_requested)
	code_edit.text_changed.connect(_on_code_text_changed)
	tab_container.tab_changed.connect(_on_tab_changed)

func _on_code_text_changed() -> void:
	# Força o pedido de autocomplete ao digitar
	code_edit.request_code_completion()

const COMMAND_SCENES = {
	"andar": preload("res://commands/ComandoAndar.tscn"),
	"virar": preload("res://commands/ComandoVirar.tscn"),
	"pular": preload("res://commands/ComandoPular.tscn"),
	"parar": preload("res://commands/ComandoParar.tscn"),
	"esperar": preload("res://commands/ComandoEsperar.tscn"),
	"repetir": preload("res://commands/ComandoRepetir.tscn"),
	"se": preload("res://commands/ComandoSe.tscn"),
}

func _on_tab_changed(tab: int) -> void:
	if tab == 1:
		# Indo para aba Código — sempre gera texto a partir dos blocos atuais
		code_edit.text = _blocks_to_code()
	elif tab == 0:
		# Indo para aba Blocos — converte código em blocos
		if not code_edit.text.strip_edges().is_empty():
			_code_to_blocks()

# === Sincronização código → blocos ===

func _code_to_blocks() -> void:
	var available = _get_available_command_names()
	var result = CodeParser.parse(code_edit.text, available)
	if not result.success:
		return

	# Limpa blocos atuais
	for child in target_node.get_children():
		if child != drop_indicator:
			child.queue_free()

	await get_tree().process_frame

	# Cria blocos a partir dos comandos parseados
	_create_blocks_from_comandos(result.comandos, target_node)
	_update_block_numbers()

func _create_blocks_from_comandos(comandos: Array, container: Node) -> void:
	for cmd_data in comandos:
		var mock = cmd_data[0]
		if not mock or not mock.has_method("get_command_type"):
			continue

		var cmd_type = mock.get_command_type()
		var cmd_name = COMMAND_NAMES[cmd_type] if cmd_type < COMMAND_NAMES.size() else ""

		if cmd_name.is_empty() or cmd_name not in COMMAND_SCENES:
			continue

		var block = COMMAND_SCENES[cmd_name].instantiate()
		container.add_child(block)

		# Configura parâmetros
		match cmd_type:
			4:  # Esperar
				var tempo_input = block.get_node_or_null("TempoInput")
				if tempo_input:
					tempo_input.value = mock.get_valor()
			5:  # Repetir
				var rep_input = block.get_node_or_null("repeticaoInput")
				if rep_input:
					rep_input.value = mock.get_repeat_count()
				# Filhos
				var inner_container = block.get_node_or_null("VBoxContainer")
				if inner_container and mock._inner_comandos.size() > 0:
					_create_blocks_from_comandos(mock._inner_comandos, inner_container)
			6:  # Se
				var option_btn = block.get_node_or_null("OptionButton")
				if option_btn:
					var condition = mock.get_condition()
					match condition:
						"on_ground": option_btn.selected = 0
						"obstacle_ahead": option_btn.selected = 1
						"facing_right": option_btn.selected = 2
						"facing_left": option_btn.selected = 3
						"hole_ahead": option_btn.selected = 4
				# Filhos
				var inner_container = block.get_node_or_null("VBoxContainer")
				if inner_container and mock._inner_comandos.size() > 0:
					_create_blocks_from_comandos(mock._inner_comandos, inner_container)

# === Sincronização blocos → código ===

func _blocks_to_code() -> String:
	return _nodes_to_code(target_node, 0)

func _nodes_to_code(container: Node, indent: int) -> String:
	var code := ""
	var tabs := "\t".repeat(indent)
	for child in container.get_children():
		if child == drop_indicator:
			continue
		if not (child is TextureRect) or not child.has_method("get_command_type"):
			continue

		var cmd_type = child.get_command_type()
		match cmd_type:
			0: code += tabs + "andar();\n"
			1: code += tabs + "virar();\n"
			2: code += tabs + "pular();\n"
			3: code += tabs + "parar();\n"
			4:
				var tempo = child.get_valor() if child.has_method("get_valor") else 1.0
				code += tabs + "esperar(%s);\n" % tempo
			5:
				var count = child.get_repeat_count()
				code += tabs + "repetir(%d) {\n" % count
				var inner_container = child.get_node_or_null("VBoxContainer")
				if inner_container:
					code += _nodes_to_code(inner_container, indent + 1)
				code += tabs + "}\n"
			6:
				var condition = child.get_condition()
				var cond_text = _condition_to_text(condition)
				code += tabs + "se(%s) {\n" % cond_text
				var inner_container = child.get_node_or_null("VBoxContainer")
				if inner_container:
					code += _nodes_to_code(inner_container, indent + 1)
				code += tabs + "}\n"
	return code

func _condition_to_text(condition: String) -> String:
	match condition:
		"on_ground": return "no_chao"
		"obstacle_ahead": return "obstaculo_a_frente"
		"facing_right": return "virado_direita"
		"facing_left": return "virado_esquerda"
		"hole_ahead": return "buraco_a_frente"
		_: return condition

func _on_code_completion_requested() -> void:
	var available = _get_available_command_names()

	# Detecta se estamos dentro de se(...)
	var line_text = code_edit.get_line(code_edit.get_caret_line())
	var caret_col = code_edit.get_caret_column()
	var text_before_caret = line_text.substr(0, caret_col)
	var inside_se = text_before_caret.find("se(") != -1 and text_before_caret.find(")") == -1

	if inside_se:
		for cond_name in CONDITION_DESCRIPTIONS:
			var desc = CONDITION_DESCRIPTIONS[cond_name]
			code_edit.add_code_completion_option(CodeEdit.KIND_VARIABLE, cond_name + " — " + desc, cond_name, Color(0.6, 0.9, 0.6))
	else:
		for cmd_name in available:
			var desc = COMMAND_DESCRIPTIONS.get(cmd_name, "")
			var insert_text = cmd_name
			if cmd_name in ["andar", "virar", "pular", "parar"]:
				insert_text = cmd_name + "();"
			elif cmd_name == "esperar":
				insert_text = cmd_name + "(1.0);"
			elif cmd_name == "repetir":
				insert_text = cmd_name + "(1) {\n\t\n}"
			elif cmd_name == "se":
				insert_text = cmd_name + "() {\n\t\n}"
			code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, cmd_name + " — " + desc, insert_text, Color(0.6, 0.8, 1.0))

	code_edit.update_code_completion_options(true)

func _count_total_commands(comandos: Array) -> int:
	var total := 0
	for cmd_data in comandos:
		var cmd = cmd_data[0]
		if not cmd or not is_instance_valid(cmd) or not cmd.has_method("get_command_type"):
			continue
		total += 1
		var ct = cmd.get_command_type()
		if ct == 5:
			var inner = cmd.get_comandos()
			total += _count_total_commands(inner) * cmd.get_repeat_count()
		elif ct == 6:
			total += _count_total_commands(cmd.get_comandos())
	return total

func _highlight_command(comando: Node) -> void:
	# Limpa highlights anteriores
	for child in target_node.get_children():
		if child is TextureRect:
			child.modulate = Color.WHITE
	# Destaca o atual
	if comando and is_instance_valid(comando) and comando is TextureRect:
		comando.modulate = Color(1.0, 1.0, 0.5, 1.0)

func _update_step_counter() -> void:
	if error_label:
		error_label.text = "Passo %d/%d" % [_exec_step, _exec_total]
		error_label.visible = true
		error_label.remove_theme_color_override("font_color")
		error_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))

func _update_block_numbers() -> void:
	var index := 1
	for child in target_node.get_children():
		if child == drop_indicator:
			continue
		if child is TextureRect and child.has_method("get_command_type"):
			child.tooltip_text = "%d" % index
			index += 1

func _clear_execution_feedback() -> void:
	for child in target_node.get_children():
		if child is TextureRect:
			child.modulate = Color.WHITE
	if error_label:
		error_label.visible = false

func executar_sequencial(comandos, is_root := true):
	find_map_and_player()

	if not player:
		print("⚠️ Nenhum player encontrado para executar os comandos.")
		return

	if is_root:
		_exec_step = 0
		_exec_total = _count_total_commands(comandos)

	for comando_data in comandos:
		var comando = comando_data[0]

		if not comando or not is_instance_valid(comando):
			continue
		if not comando.has_method("get_command_type"):
			continue

		var command_type = comando.get_command_type()

		var nome_comando: String = ""
		if command_type >= 0 and command_type < COMMAND_NAMES.size():
			nome_comando = COMMAND_NAMES[command_type]
		else:
			continue

		_exec_step += 1
		_highlight_command(comando)
		_update_step_counter()

		if map and map.has_method("registrar_comando"):
			map.registrar_comando(nome_comando)

		match command_type:
			0:  # Andar
				if player.has_method("andar"):
					player.andar()
			1:  # Virar
				player.virar()
			2:  # Pular
				player.pular()
			3:  # Parar
				player.parar()
			4:  # Esperar
				var tempo = comando_data[1]
				await player.esperar(tempo)
			5:  # Repetir
				var repeat_count = comando.get_repeat_count()
				var inner_comandos = comando.get_comandos()
				for _i in range(repeat_count):
					await executar_sequencial(inner_comandos, false)
			6:  # Se
				var condition = comando.get_condition()
				var inner_comandos = comando.get_comandos()

				while player and is_instance_valid(player) and not player.check_condition(condition):
					await get_tree().process_frame

				if not player or not is_instance_valid(player):
					return

				await executar_sequencial(inner_comandos, false)

				while player and is_instance_valid(player) and player.check_condition(condition):
					await get_tree().process_frame

		# Delay entre passos para o highlight ser visível
		await get_tree().create_timer(0.3).timeout
