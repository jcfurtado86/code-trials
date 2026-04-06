extends CharacterBody2D

signal player_died()

const SCALE_FACTOR = 2.5

const SPEED = 100.0 * SCALE_FACTOR
const JUMP_VELOCITY = -200.0 * SCALE_FACTOR
const RAYCAST_DISTANCE = 25 * SCALE_FACTOR  # Distância para detectar obstáculos
const HOLE_DETECTION_DISTANCE = 50.0 * SCALE_FACTOR  # Distância para detectar buracos

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") 
var is_jumping := false
var is_moving := false
var direction := 1  # 1 = Direita, -1 = Esquerda
var max_health := 1
var current_health := max_health
var is_dead := false

@onready var texture := $AnimatedSprite2D as AnimatedSprite2D
@onready var step_timer := $StepTimer as Timer

func _physics_process(delta: float) -> void:
	# Adiciona a gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Aplica o movimento apenas se estiver andando
	if is_moving:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	_set_state()
	move_and_slide()
	_gerenciar_som_passos()

func _set_state():
	var state = 'idle'
	
	if !is_on_floor():
		state = 'jump'
	elif is_moving:
		state = 'run'
	
	if texture.name != state:
		texture.play(state)

func take_damage(knockback_force: Vector2) -> void:
	current_health -= 1
	
	velocity = knockback_force
	
	# Efeito visual de dano
	$AnimatedSprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	if is_instance_valid(SoundManager):
		SoundManager.play_death()
	#$AnimatedSprite2D.play("death")
	
	await get_tree().create_timer(0.5).timeout
	# Emite o sinal de morte
	emit_signal("player_died")

func _gerenciar_som_passos():
	var deve_andar = is_moving and is_on_floor()
	
	# Se deve andar E o timer está parado, comece o timer.
	if deve_andar and step_timer.is_stopped():
		step_timer.start()
		SoundManager.play_step()
	
	# Se NÃO deve andar E o timer está rodando, pare o timer.
	elif not deve_andar and not step_timer.is_stopped():
		step_timer.stop()
		

func _on_step_timer_timeout():
	if is_instance_valid(SoundManager):
		SoundManager.play_step()

# ====== COMANDOS EXTERNOS ======

func andar():
	is_moving = true

func virar():
	direction *= -1
	texture.scale.x = -direction

func pular():
	if is_instance_valid(SoundManager):
		SoundManager.play_jump()
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func parar():
	is_moving = false
	
func esperar(tempo):
	await get_tree().create_timer(tempo).timeout

# ====== SISTEMA DE CONDIÇÕES ======

func check_condition(condition: String) -> bool:
	match condition:
		"on_ground":
			return is_on_floor()
		"obstacle_ahead":
			return _has_obstacle_ahead()
		"facing_right":
			return (direction == 1)
		"facing_left":
			return (direction == -1)
		"hole_ahead":
			return !_has_ground_ahead()
		_:
			return false

func _has_obstacle_ahead() -> bool:
	var space_state = get_world_2d().direct_space_state
	var ray_direction = Vector2.RIGHT if direction > 0 else Vector2.LEFT
	var player_height = 35.0 * SCALE_FACTOR
	var ray_count = 3
	var ray_spacing = player_height / (ray_count - 1)
	var base_y = global_position.y + (player_height / 2)
	
	for i in ray_count:
		var y_offset = -i * ray_spacing
		var start_pos = Vector2(global_position.x, base_y + y_offset)
		var end_pos = start_pos + ray_direction * RAYCAST_DISTANCE
		
		var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
		query.exclude = [self]
		query.collision_mask = collision_mask
		
		var result = space_state.intersect_ray(query)
		if result.has("collider"):
			return true
	
	return false

func _has_ground_ahead() -> bool:
	var space_state = get_world_2d().direct_space_state
	var ray_direction = Vector2.RIGHT if direction > 0 else Vector2.LEFT
	
	# Ajuste estes valores conforme necessário
	var forward_offset = 30 * SCALE_FACTOR  # Distância à frente do personagem
	var vertical_offset = -10 * SCALE_FACTOR  # Ajuste vertical (negativo = acima dos pés)
	
	var start_pos = global_position + ray_direction * forward_offset + Vector2(0, vertical_offset)
	var end_pos = start_pos + Vector2.DOWN * HOLE_DETECTION_DISTANCE
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.exclude = [self]  # Ignora o próprio jogador
	query.collision_mask = collision_mask  # Usa a mesma máscara do personagem
	
	var result = space_state.intersect_ray(query)
	return result.has("collider")  # Forma mais confiável
