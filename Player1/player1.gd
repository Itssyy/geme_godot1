extends CharacterBody2D

@export var health = 100
const SPEED = 200.0
const JUMP_VELOCITY = -320.0
const GRAVITY = 19.0
const JUMP_APEX_THRESHOLD = 10.0

enum Player_state { JUMP, ATTACK, MOVE, DAMAGE, }
signal health_changed(new_health)
var current_state = Player_state.MOVE

var is_jumping = false
var is_falling = false
var can_attack = true

@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var attack_area = $Area2D
@onready var attack_shape_left = $Area2D/CollisionShape2DLeft
@onready var attack_shape_right = $Area2D/CollisionShape2DRight
@onready var health_label = $HealthLabel

func _ready():
	print("Player script ready")
	$Area2D2.connect("body_entered", Callable(self, "_on_body_entered"))
	connect("health_changed", Callable(self, "_on_health_changed"))
	print("Connected health_changed signal")
	_update_health_label()  # Обновляем метку при запуске

func _physics_process(delta):
	match current_state:
		Player_state.MOVE:
			move_state(delta)
		Player_state.DAMAGE:
			damage_state()
		Player_state.JUMP:
			jump_state(delta)
		Player_state.ATTACK:
			attack_state()

func _on_body_entered(body):
	print("Body entered area")
	if body.has_method('_on_attack_area_entered'):
		print("Body has method _on_attack_area_entered")
		take_damage(body.damage)
	else:
		print("Body does not have method _on_attack_area_entered")

func take_damage(damage: int):
	print("Taking damage: ", damage)
	health -= damage
	emit_signal("health_changed", health)
	print("Emitting health_changed signal with health: ", health)
	if health <= 0:
		die()

func _on_health_changed(new_health):
	print("Health changed: ", new_health)
	_update_health_label()  # Обновляем метку при изменении здоровья

func _update_health_label():
	health_label.text = str(health)  # Обновляем текст метки

func die():
	print("Player died")
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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		anim_player.play("idle")

	if Input.is_action_just_pressed("attack") and can_attack:
		current_state = Player_state.ATTACK
		update_attack_area_position()

	move_and_slide()

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
	can_attack = false

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		attack_area.visible = false
		current_state = Player_state.MOVE
		can_attack = true

func _process(delta):
	Global.player_position = global_position

func update_attack_area_position():
	var mouse_position = get_global_mouse_position()
	var player_position = global_position
	if mouse_position.x > player_position.x:
		attack_shape_left.disabled = true
		attack_shape_right.disabled = false
	else:
		attack_shape_left.disabled = false
		attack_shape_right.disabled = true

