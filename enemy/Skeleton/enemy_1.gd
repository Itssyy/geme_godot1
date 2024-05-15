extends CharacterBody2D

# Массив точек патрулирования (заполните в инспекторе)
@export var waypoints: Array[Vector2] = []
# Скорость движения
@export var speed: float = 85.0
# Время ожидания в каждой точке
@export var wait_time: float = 4.0
# Сила гравитации
@export var gravity: float = 980.0

# Ссылка на AnimatedSprite2D (добавьте в инспекторе)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Индекс текущей точки патрулирования
var current_waypoint_index: int = 0
# Таймер для паузы в точках патрулирования
var wait_timer: float = 0.0

# Перечисление состояний
enum State { PATROL, WAIT, CHASE }
# Текущее состояние
var current_state: State = State.PATROL

# Ссылка на игрока
var player: Node = null

func _ready() -> void:
	# Преобразуем локальные координаты точек патрулирования в глобальные
	for i in range(waypoints.size()):
		waypoints[i] = to_global(waypoints[i])

func _physics_process(delta: float) -> void:
	# Проверка на пустой массив waypoints
	if waypoints.is_empty():
		print("Ошибка: Массив waypoints пуст. Добавьте точки патрулирования в инспекторе.")
		return

	# Применяем гравитацию, если не на земле
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		State.PATROL:
			_patrol(delta)
		State.WAIT:
			_wait(delta)
		State.CHASE:
			# Преследуем игрока, только если на земле
			if is_on_floor():
				_chase(delta)
			else:
				current_state = State.PATROL  # Возвращаемся к патрулированию
				player = null  # Сбрасываем игрока
				print("Потерял игрока из виду, продолжаю патрулирование")

func _patrol(delta: float) -> void:
	# Получаем текущую точку патрулирования
	var current_waypoint: Vector2 = waypoints[current_waypoint_index]

	# Вычисляем направление и расстояние до текущей точки патрулирования
	var direction_to_waypoint: Vector2 = current_waypoint - global_position
	var distance_to_waypoint: float = direction_to_waypoint.length()

	# Если достигли текущей точки патрулирования
	if distance_to_waypoint < 5.0:
		current_state = State.WAIT
		wait_timer = 0.0
		animated_sprite.play("idle") 
		print("Достигнута точка патрулирования. Ожидание...")
	else:
		# Двигаемся к текущей точке патрулирования
		velocity = direction_to_waypoint.normalized() * speed
		move_and_slide()
		animated_sprite.play("run") 

		# Разворачиваем спрайт врага в сторону движения
		if velocity.x > 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true

func _wait(delta: float) -> void:
	wait_timer += delta
	if wait_timer >= wait_time:
		current_state = State.PATROL
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		print("Ожидание завершено. Продолжаю патрулирование")

func _chase(delta: float) -> void:
	if player != null:
		var direction_to_player: Vector2 = player.global_position - global_position
		var distance_to_player: float = direction_to_player.length()

		if distance_to_player > 200:  # Если игрок вышел из зоны обнаружения
			current_state = State.PATROL  # Возвращаемся к патрулированию
			player = null  # Обнуляем ссылку на игрока
			print("Игрок потерян, возвращаюсь к патрулированию")
		else:
			velocity = direction_to_player.normalized() * speed
			move_and_slide()

			# Поворот спрайта в сторону игрока
			if velocity.x > 0:
				animated_sprite.flip_h = false
			else:
				animated_sprite.flip_h = true

			print("Преследую игрока на расстоянии:", distance_to_player)
	else:
		current_state = State.PATROL
		print("Игрок не найден, продолжаю патрулирование")

func _on_detekted_zona_body_entered(body):
	if body.has_method("player"):
		player = body 
		current_state = State.CHASE 
		print("Игрок обнаружен! Перехожу в режим преследования")

func _on_detekted_zona_body_exited(body):
	if body.has_method('player'):
		current_state = State.PATROL

