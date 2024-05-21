extends TextureProgressBar

@onready var enemy= $".."
@onready var hpbar = $"."


func _process(delta):

	value = enemy.health
	
	
