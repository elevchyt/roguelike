extends Node2D

# Play animation once & remove instance
func _on_AnimatedSprite_animation_finished():
	queue_free()
