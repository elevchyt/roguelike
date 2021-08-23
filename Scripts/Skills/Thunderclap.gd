extends Node2D

var enemiesToHit : Array

# Remove instance when animation is finisheed
func _on_AnimatedSprite_animation_finished():
	queue_free()

# Store all enemies in hurt box
func _on_Area2D_area_entered(area):
	if (area.get_parent().isMonster == true):
		enemiesToHit.append(area.get_parent())
