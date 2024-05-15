extends CharacterBody2D

# Константы, определяющие скорость перемещения, скорость прыжка и силу гравитации
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 20.0
const JUMP_APEX_THRESHOLD = 10.0  # Пороговое значение для определения вершины прыжка

# Перечисление для различных состояний персонажа
enum Player_state { JUMP, ATTACK, MOVE, DAMAGE, CHASE }

# Начальное состояние персонажа
var current_state = Player_state.MOVE

# Флаги для отслеживания состояния прыжка
var is_jumping = false
var is_falling = false

# Ссылка на AnimatedSprite2D для воспроизведения анимаций
@onready var sprite = $AnimatedSprite2D

# Функция, вызываемая на каждом кадре физического движка
func _physics_process(delta):
	# Выбор соответствующей функции состояния в зависимости от текущего состояния персонажа
	match current_state:
		Player_state.MOVE:
			move_state(delta)
		Player_state.DAMAGE:
			damage_state()
		Player_state.JUMP:
			jump_state(delta)

# Функция для обработки состояния движения
func move_state(delta):
	# Применение гравитации к вертикальной скорости персонажа
	velocity.y += GRAVITY

	# Обработка начала прыжка при нажатии соответствующей кнопки и нахождении персонажа на земле
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		is_falling = false
		current_state = Player_state.JUMP

	# Получение направления движения по горизонтали
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		# Обновление горизонтальной скорости персонажа
		velocity.x = direction * SPEED
		# Отражение спрайта в зависимости от направления движения
		sprite.flip_h = direction < 0
		# Воспроизведение анимации бега
		sprite.play("run")
	else:
		# Замедление горизонтального движения при отсутствии ввода
		velocity.x = move_toward(velocity.x, 0, SPEED)
		# Воспроизведение анимации простоя
		sprite.play("idle")

	# Перемещение персонажа
	move_and_slide()

# Функция для обработки состояния повреждения
func damage_state():
	# Остановка движения персонажа
	velocity = Vector2.ZERO
	# Воспроизведение анимации "hurt"
	sprite.play("hurt")
	# Здесь можно добавить код для уменьшения здоровья персонажа и проверки его смерти

# Функция для обработки состояния прыжка
func jump_state(delta):
	# Применение гравитации к вертикальной скорости персонажа
	velocity.y += GRAVITY

	# Воспроизведение анимации подъема при прыжке и отрицательной вертикальной скорости
	if is_jumping and velocity.y < 0:
		sprite.play("jump_up")
	# Воспроизведение анимации падения при нахождении в состоянии падения
	elif is_falling:
		sprite.play("jump_down")

	# Установка флага падения при достижении вершины прыжка
	if velocity.y >= JUMP_APEX_THRESHOLD:
		is_falling = true
		is_jumping = false

	# Сброс флагов прыжка и падения после приземления
	if is_on_floor():
		is_jumping = false
		is_falling = false
		current_state = Player_state.MOVE

	# Перемещение персонажа
	move_and_slide()

# Функция для обработки состояния атаки (пока пустая)
func attack_state():
	velocity = Vector2.ZERO
	# sprite.play("attack")
	# Здесь можно добавить код для атаки врагов

# Функция для обработки состояния преследования (пока пустая)
func chase_state():
	pass
