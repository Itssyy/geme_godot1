
extends CharacterBody2D

@export var waypoints: Array[Vector2] = []
@export var speed: float = 20.0
@export var wait_time: float = 4.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim = $AnimationPlayer
@onready var hit_box = $hit_box/CollisionShape2D
@onready var waypoints_parent: Node2D = $WaypointsParent
var current_waypoint_index: int = 0
var wait_timer: float = 0.0
enum State { PATROL, WAIT, CHASE, ATTACK , DEATH , DAMAGE }
var current_state: State = State.PATROL
@export var attack_distance: float = 25.0
var push_back_distance: float = 0.2
@export var max_health = 50
var health = max_health
@export var damage = 1


func _ready() -> void:
	# Преобразуем локальные координаты точек патрулирования в глобальные
	for i in range(waypoints.size()):
		waypoints[i] = to_global(waypoints[i])
	
	$AnimationPlayer.connect("animation_finished", Callable(self, "_on_animation_finished"))



func _on_hit_box_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

func take_damage(damage):
	health -= damage
	print(damage)
	if health <=0:
		current_state = State.DEATH
	else:
		current_state = State.DAMAGE

func die() -> void:
	#anim.play("daeth")
	#await anim.animation_finished
	queue_free()
	
func damage_state():
	velocity = Vector2.ZERO  # Остановить движение во время анимации
	 # Запустить анимацию 
	
func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		print("Ошибка: Массив waypoints пуст. Добавьте точки патрулирования в инспекторе.")
		return
	velocity.y += gravity * delta

	match current_state:
		State.PATROL:
			_patrol(delta)
		State.WAIT:
			_wait(delta)
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)
		State.DEATH:
			die()
		State.DAMAGE:
			damage_state()
			

func _patrol(delta: float) -> void:
	var current_waypoint: Vector2 = waypoints[current_waypoint_index]
	var direction_to_waypoint: Vector2 = current_waypoint - global_position
	var distance_to_waypoint: float = direction_to_waypoint.length()

	if distance_to_waypoint < 5.0:
		current_state = State.WAIT
		wait_timer = 0.0
		anim.play("idle")
		print("Достигнута точка патрулирования. Ожидание...")
	else:
		velocity = direction_to_waypoint.normalized() * speed
		move_and_slide()
		anim.play("run")
		if velocity.x > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true

func _wait(delta: float) -> void:
	wait_timer += delta
	if wait_timer >= wait_time:
		current_state = State.PATROL
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func _chase(delta: float) -> void:
	var player_position = Global.player_position
	var direction_to_player_x: float = player_position.x - global_position.x  # Получаем только разницу по X
	var distance_to_player_x: float = abs(direction_to_player_x)  # Используем абсолютное значение для корректного направления

	if distance_to_player_x > 700:
		current_state = State.PATROL
		print("Игрок потерян, возвращаюсь к патрулированию")
	elif distance_to_player_x <= attack_distance:
		current_state = State.ATTACK
	else:
		velocity.x = sign(direction_to_player_x) * speed  # Устанавливаем горизонтальную скорость в направлении игрока
		velocity.y = 0  # Обнуляем вертикальную скорость
		move_and_slide()
		if velocity.x > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
			anim.play("run")

func _attack(delta: float) -> void:
	var player_position = Global.player_position
	var direction_to_player_x: float = player_position.x - global_position.x
	var distance_to_player_x: float = abs(direction_to_player_x)

	if distance_to_player_x > 150:
		# Если игрок вышел из зоны атаки, переходим к преследованию
		current_state = State.CHASE
		print("Игрок вышел из зоны атаки. Переход к преследованию.")
	else:
		anim.play("attack")
		velocity = Vector2.ZERO  # Останавливаем движение во время атаки

		# Отодвигаем врага в сторону от игрока
		var push_back_vector_x: float = -sign(direction_to_player_x) * push_back_distance
		global_position.x += push_back_vector_x * delta

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "attack" and current_state == State.ATTACK:
		hit_box.disabled = true
		# Анимация атаки закончилась, возвращаемся к преследованию
		current_state = State.CHASE


func _on_detekted_zona_body_entered(body):
	if body.name == "Player":
		current_state = State.CHASE

func _on_detekted_zona_body_exited(body):
	if body.name == "Player":
		current_state = State.PATROL
