extends Node2D

onready var Player = get_parent().get_parent()
onready var TargetDestination = Player.get_node('Target').position

# Run hit animation on target destination arrival
func _process(delta):
	if (position == TargetDestination):
		$AnimatedSprite.animation = 'hit'

# Remove instance after 'hit' animation plays once
func _on_AnimatedSprite_animation_finished():
	if ($AnimatedSprite.animation == 'hit'):
		queue_free()
