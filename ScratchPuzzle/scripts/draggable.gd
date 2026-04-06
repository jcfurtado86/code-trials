extends TextureRect

@export_enum("Andar", "Virar", "Pular", "Parar", "Esperar", "Repetir", "Se") var CommandType = 0
@export var valor: float = 1.0
@export var repeat_count: int = 1

# Variáveis que podem ou não existir, não use @onready aqui
var tempo_input: SpinBox
var repeticao_input: SpinBox
var command_container: VBoxContainer
var condition_option: OptionButton
var nine_patch_rect: NinePatchRect

# Chamado quando o nó é inicializado
func _ready():
	# Andar, Virar, Pular, Esperar
	if CommandType == 4:
		tempo_input = get_node_or_null("TempoInput")
	# Repetir
	if CommandType == 5:
		command_container = get_node_or_null("VBoxContainer")
		repeticao_input = get_node_or_null("repeticaoInput")
		nine_patch_rect = get_node_or_null("NinePatchRect")
		if repeticao_input:
			repeticao_input.get_line_edit().focus_entered.connect(func(): repeticao_input.get_line_edit().select_all())
			var timer = Timer.new()
			timer.one_shot = true
			timer.wait_time = 0.5
			timer.timeout.connect(func(): repeticao_input.apply())
			repeticao_input.add_child(timer)
			repeticao_input.get_line_edit().text_changed.connect(func(_t): timer.start())
	# Se
	if CommandType == 6:
		command_container = get_node_or_null("VBoxContainer")
		condition_option = get_node_or_null("OptionButton")
		nine_patch_rect = get_node_or_null("NinePatchRect")
		_setup_condition_options()

func _process(_delta):
	if CommandType in [5, 6] and command_container:
		# espera o layout atualizar
		await get_tree().process_frame
		
		var total_height = 30
		for child in command_container.get_children():
			total_height += child.get_combined_minimum_size().y + command_container.get_theme_constant("separation")
		
		custom_minimum_size.y = total_height
		nine_patch_rect.custom_minimum_size.y = total_height - 15


# Adicione esta função ao seu bloco de comando (CommandBlock.gd)
func get_command_type() -> int:
	return CommandType

# Configura as opções de condição no OptionButton
func _setup_condition_options():
	if condition_option:
		condition_option.clear()
		condition_option.add_item("Está no chão?")
		condition_option.add_item("Há obstáculo à frente?")
		condition_option.add_item("Está virado para direita?")
		condition_option.add_item("Está virado para esquerda?")
		condition_option.add_item("Há um buraco à frente?")

# Retorna o tipo de condição selecionada (apenas para comando "Se")
func get_condition() -> String:
	if CommandType == 6 && condition_option:
		match condition_option.selected:
			0: return "on_ground"
			1: return "obstacle_ahead"
			2: return "facing_right"
			3: return "facing_left"
			4: return "hole_ahead"
	return ""

func get_comandos():
	var comandos = []
	for child in command_container.get_children():
		if child is TextureRect:
			var tempo = child.get_valor() if child.has_method("get_valor") else 1.0
			comandos.append([child, tempo])
	return comandos

func get_repeat_count() -> int:
	return int(repeticao_input.value) if repeticao_input else repeat_count

func get_valor() -> float:
	return float(tempo_input.value) if tempo_input else 1.0

func _get_drag_data(_at_position: Vector2) -> Variant:
	var parent = get_parent()
	if parent and parent.has_method("is_transitioning") and parent.is_transitioning:
		return null

	var preview = TextureRect.new()
	preview.texture = texture
	preview.modulate = Color(1, 1, 1, 0.7)
	set_drag_preview(preview)
	return [self]

func _is_in_palette() -> bool:
	var parent = get_parent()
	return parent and parent is GridContainer

func _enter_tree() -> void:
	# Desabilita inputs dos SpinBoxes quando na paleta de comandos
	call_deferred("_update_input_mode")

func _update_input_mode() -> void:
	var in_palette = _is_in_palette()
	if tempo_input:
		tempo_input.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_palette else Control.MOUSE_FILTER_STOP
		tempo_input.get_line_edit().mouse_filter = Control.MOUSE_FILTER_IGNORE if in_palette else Control.MOUSE_FILTER_STOP
	if repeticao_input:
		repeticao_input.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_palette else Control.MOUSE_FILTER_STOP
		repeticao_input.get_line_edit().mouse_filter = Control.MOUSE_FILTER_IGNORE if in_palette else Control.MOUSE_FILTER_STOP
	if condition_option:
		condition_option.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_palette else Control.MOUSE_FILTER_STOP

func _notification(notification_type) -> void:
	match notification_type:
		NOTIFICATION_DRAG_END:
			visible = true

func set_inside_container(is_inside: bool):
	if is_inside:
		modulate = Color(0.9, 0.9, 1.0)  # Tom azulado claro
	else:
		modulate = Color.WHITE
