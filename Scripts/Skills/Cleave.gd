extends Node2D

var enemiesToHit : Array
	
# Store all enemies in hurt box
func _on_Area2D_area_entered(area):
	if (area.get_parent().isMonster == true):
		enemiesToHit.append(area.get_parent())
