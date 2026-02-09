extends Control

@onready var bg_overlay: ColorRect = $bg_overlay
@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel

enum TutorialStep {
	OBJECTIVES,
	COMMANDS,
	EXECUTION
}

const OBJECTIVES_POS: Vector2 = Vector2(1425, 80)
const COMMANDS_POS: Vector2   = Vector2(175, 125)
const EXECUTION_POS: Vector2  = Vector2(40, 398)

const OBJECTIVES_RADIUS_PX: float = 450.0
const COMMANDS_RADIUS_PX: float = 450.0
const EXECUTION_RADIUS_PX: float = 450.0

func _ready() -> void:
	tutorial_step(TutorialStep.OBJECTIVES)

func tutorial_step(step: TutorialStep) -> void:
	match step:
		TutorialStep.OBJECTIVES:
			panel.position = Vector2(800, 60)
			label.text = "Este é o painel de objetivos.\nAqui você vê o que precisa fazer para completar o nível."
			highlight_position(OBJECTIVES_POS, OBJECTIVES_RADIUS_PX)
		TutorialStep.COMMANDS:
			panel.position = Vector2(450, 60)
			label.text = "Aqui ficam os comandos.\nArraste-os para área de execução para montar o algoritmo."
			highlight_position(COMMANDS_POS, COMMANDS_RADIUS_PX)
		TutorialStep.EXECUTION:
			panel.position = Vector2(450, 550)
			label.text = "Esta é a área de execução.\nClique em executar para rodar o algoritmo montado."
			highlight_position(EXECUTION_POS, EXECUTION_RADIUS_PX)

func highlight_position(pixel_position: Vector2, radius_px: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var normalized_pos: Vector2 = pixel_position / viewport_size
	var normalized_radius: float = radius_px / viewport_size.x

	var material: ShaderMaterial = bg_overlay.material as ShaderMaterial
	material.set_shader_parameter("hole_position", normalized_pos)
	material.set_shader_parameter("hole_radius", normalized_radius)
