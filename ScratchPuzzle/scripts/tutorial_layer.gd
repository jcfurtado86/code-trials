extends Control

@onready var bg_overlay: ColorRect = $bg_overlay
@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel

enum TutorialStep {
	OBJECTIVES,
	COMMANDS_AREA,
	COMMANDS_BLOCK,
	EXECUTION
}

var current_step: TutorialStep = TutorialStep.OBJECTIVES
const OBJECTIVES_POS: Vector2 = Vector2(1425, 80)
const COMMANDS_POS: Vector2 = Vector2(175, 125)
const EXECUTION_POS: Vector2 = Vector2(175, 700)

const OBJECTIVES_RADIUS_PX: float = 450.0
const COMMANDS_RADIUS_PX: float = 450.0
const EXECUTION_RADIUS_PX: float = 500.0

func _ready() -> void:
	current_step = TutorialStep.OBJECTIVES
	tutorial_step(current_step)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_next_step()

func _next_step() -> void:
	match current_step:
		TutorialStep.OBJECTIVES:
			current_step = TutorialStep.COMMANDS_AREA
			tutorial_step(current_step)
		TutorialStep.COMMANDS_AREA:
			current_step = TutorialStep.COMMANDS_BLOCK
			tutorial_step(current_step)
		TutorialStep.COMMANDS_BLOCK:
			current_step = TutorialStep.EXECUTION
			tutorial_step(current_step)
		TutorialStep.EXECUTION:
			_finish_tutorial()


func _finish_tutorial() -> void:
	queue_free()

func tutorial_step(step: TutorialStep) -> void:
	match step:
		TutorialStep.OBJECTIVES:
			panel.position = Vector2(800, 60)
			label.text = "Este é o painel de objetivos.\nAqui você vê o que precisa fazer para completar o nível."
			highlight_position(OBJECTIVES_POS, OBJECTIVES_RADIUS_PX)

		TutorialStep.COMMANDS_AREA:
			panel.position = Vector2(450, 60)
			label.text = "Aqui ficam os comandos.\nArraste-os para área de execução para montar o algoritmo."
			highlight_position(COMMANDS_POS, COMMANDS_RADIUS_PX)

		TutorialStep.COMMANDS_BLOCK:
			panel.position = Vector2(450, 100)
			label.text = "Este é o comando ANDAR.\nAo executar, o player anda continuamente para direção em que está olhando."

			highlight_position(COMMANDS_POS, COMMANDS_RADIUS_PX)

		TutorialStep.EXECUTION:
			panel.position = Vector2(500, 550)
			label.text = "Esta é a área de execução.\nClique em executar para rodar o algoritmo montado."
			highlight_position(EXECUTION_POS, EXECUTION_RADIUS_PX)

func highlight_position(pixel_position: Vector2, radius_px: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var normalized_pos: Vector2 = pixel_position / viewport_size
	var normalized_radius: float = radius_px / viewport_size.x

	var material: ShaderMaterial = bg_overlay.material as ShaderMaterial
	material.set_shader_parameter("hole_position", normalized_pos)
	material.set_shader_parameter("hole_radius", normalized_radius)
