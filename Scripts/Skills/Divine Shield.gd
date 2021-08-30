extends Node2D

func _ready():
	$AnimatedSprite.playing = true

func _process(delta):
	if (get_parent().invulnerable == false):
		queue_free()
