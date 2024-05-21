extends Area2D

@export var attack_area : Area2D
@onready var attack_shape_left = $CollisionShape2DLeft
@onready var attack_shape_right = $CollisionShape2DRight

func _ready():
	reset_attack_area()

func enable_attack_area():
	attack_area.visible = true

func disable_attack_area():
	attack_area.visible = false

func update_attack_area_position(player_position: Vector2, mouse_position: Vector2):
	if mouse_position.x > player_position.x:
		attack_shape_left.disabled = true
		attack_shape_right.disabled = false
	else:
		attack_shape_left.disabled = false
		attack_shape_right.disabled = true

func reset_attack_area():
	attack_shape_left.disabled = true
	attack_shape_right.disabled = true
