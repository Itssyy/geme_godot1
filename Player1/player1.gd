extends CharacterBody2D
@export var health = 10
@export var max_health = 10
@export var dash_speed = 850 # Скорость рывка
@export var dash_distance = 160 # Расстояние рывка
@export var dash_duration = 0.1 # Длительность рывка в секундах
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const GRAVITY = 19.0
const JUMP_APEX_THRESHOLD = 10.0
var damage = 10
var attack_cooldown = 0.5 # Задержка между атаками в секундах
var time_until_next_attack = 0.0 # Время, оставшееся до следующей атаки
enum Player_state { JUMP, ATTACK, COMBO_ATTACK, MOVE, DAMAGE, DEATH , DASH }
signal health_changed(new_health)
var current_state = Player_state.MOVE
var is_jumping = false
var is_falling = false
var can_combo_attack = false  # Новая переменная для отслеживания возможности комбо-атаки
var second_attack_timer = 0.0
const SECOND_ATTACK_WINDOW = 0.2  # Время, в течение которого можно совершить вторую атаку (в секундах)
var last_move_direction = Vector2.RIGHT
var is_invincible = false
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var attack_area = $hit_box
@onready var attack_shape_left = $hit_box/CollisionShape2DLeft
@onready var attack_shape_right = $hit_box/CollisionShape2DRight

func _ready():
	print("Player script ready")
	connect("health_changed", Callable(self, "_on_health_changed"))
	print("Connected health_changed signal")
	
	reset_attack_area()

func _on_hit_box_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

func take_damage(damage):
	if is_invincible:
		return 
	health -= damage
	emit_signal("health_changed", health)
	if health <= 0:
		current_state = Player_state.DEATH
	else:
		current_state = Player_state.DAMAGE

func _physics_process(delta):
	match current_state:
		Player_state.MOVE:
			move_state(delta)
			time_until_next_attack = max(time_until_next_attack - delta, 0.0)
		Player_state.DAMAGE:
			damage_state()
		Player_state.JUMP:
			jump_state(delta)
		Player_state.ATTACK:
			attack_state()
		Player_state.COMBO_ATTACK:
			combo_attack_state(delta)
		Player_state.DEATH:
			die()
		Player_state.DASH:
			dash_state()
	
func die():
	print("Player died")
	anim_player.play("death")
	await anim_player.animation_finished
	queue_free()

func move_state(delta):
	velocity.y += GRAVITY
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		is_falling = false
		current_state = Player_state.JUMP

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
		anim_player.play("run")
		last_move_direction = Vector2(direction, 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		anim_player.play("idle")

	if Input.is_action_just_pressed("attack") and time_until_next_attack == 0.0:
		current_state = Player_state.ATTACK
		update_attack_area_position()
	if Input.is_action_just_pressed("dash"):
		current_state = Player_state.DASH

	move_and_slide()
	
func dash_state():
	is_invincible = true
	var dash_direction = last_move_direction * dash_speed
	set_collision_mask_value(3, false)
	sprite.modulate = Color(1, 1, 1, 0.4)

	velocity = dash_direction
	move_and_slide() 
	await get_tree().create_timer(dash_duration).timeout 
	sprite.modulate = Color(1, 1, 1, 1)

	is_invincible = false
	current_state = Player_state.MOVE


func damage_state():
	velocity = Vector2.ZERO
	anim_player.play("hurt")

func jump_state(delta):
	velocity.y += GRAVITY
	if is_jumping and velocity.y < 0:
		anim_player.play("jump_up")
	elif is_falling:
		anim_player.play("jump_down")

	if velocity.y >= JUMP_APEX_THRESHOLD:
		is_falling = true
		is_jumping = false

	if is_on_floor():
		is_jumping = false
		is_falling = false
		current_state = Player_state.MOVE

	move_and_slide()

func attack_state():
	velocity = Vector2.ZERO
	attack_area.visible = true
	anim_player.play("attack")
	time_until_next_attack = attack_cooldown

func combo_attack_state(delta):
	velocity = Vector2.ZERO
	attack_area.visible = true

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		attack_area.visible = false
		current_state = Player_state.MOVE
		reset_attack_area()
		can_combo_attack = true  # Разрешаем комбо-атаку после завершения обычной атаки
		second_attack_timer = 0.0  # Сбрасываем таймер второй атаки
	elif anim_name == "hurt":
		current_state = Player_state.MOVE
		can_combo_attack = false  # Сбрасываем возможность комбо-атаки после получения урона
	elif anim_name == "second_attack":
		attack_area.visible = false
		current_state = Player_state.MOVE
		reset_attack_area()
		can_combo_attack = false  # Сбрасываем возможность комбо-атаки после выполнения комбо-атаки

func _process(delta):
	Global.player_position = global_position
	# Обновление таймера для второй атаки
	if can_combo_attack:
		second_attack_timer += delta
		if second_attack_timer >= SECOND_ATTACK_WINDOW:
			can_combo_attack = false  # Сбрасываем возможность комбо-атаки после истечения времени

	# Если комбо-атака доступна и игрок нажал кнопку атаки в течение времени SECOND_ATTACK_WINDOW
	if can_combo_attack and Input.is_action_just_pressed("attack") and second_attack_timer < SECOND_ATTACK_WINDOW:
		current_state = Player_state.COMBO_ATTACK
		anim_player.play("second_attack")  # Запустить анимацию второй атаки

	if Input.is_action_just_pressed("attack") and current_state != Player_state.ATTACK and current_state != Player_state.COMBO_ATTACK and time_until_next_attack == 0.0:
		current_state = Player_state.ATTACK
		update_attack_area_position()

func update_attack_area_position():
	var mouse_position = get_global_mouse_position()
	var player_position = global_position

	if mouse_position.x > player_position.x:
		attack_shape_left.disabled = true
		attack_shape_right.disabled = false
	else:
		attack_shape_left.disabled = false
		attack_shape_right.disabled = true
	
func reset_attack_area():
	attack_shape_left.disabled = true
	attack_shape_right.disabled = true
	
