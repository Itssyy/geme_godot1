extends Path2D
@export var loop = true
@export var speed = 100




# Called when the node enters the scene tree for the first time.
func _ready():
	$PathFollow2D.loop = loop

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$PathFollow2D.progress += speed * delta
