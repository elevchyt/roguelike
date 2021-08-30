extends Node2D

func _ready():
	$AnimatedSprite.playing = true

func _on_AnimatedSprite_animation_finished():
	queue_free()
