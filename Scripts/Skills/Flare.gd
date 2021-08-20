extends Node2D

onready var Player = get_parent().get_parent()
onready var TargetDestination = Player.get_node('Target').position

func _process(delta):
	if (position == TargetDestination):
		queue_free()
