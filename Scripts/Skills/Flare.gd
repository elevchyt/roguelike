extends Node2D

onready var Player = get_parent().get_parent()
onready var PlayerSkills = Player.get_node('PlayerSkills')
onready var TargetDestination = Player.get_node('Target').position
onready var CameraNode = get_node("/root/World/Camera2D")

# Run hit animation on target destination arrival
func _process(delta):
	if (position == TargetDestination):
		if (PlayerSkills.hitSuccess == true):
			# Camera Shake
			CameraNode.shake(4, 0.01, 0.1)
		
		# Reset rotation & change animation
		$AnimatedSprite.rotation = 0
		$AnimatedSprite.animation = 'hit'
		$AnimatedSprite.speed_scale = 2.5

# Remove instance after 'hit' animation plays once
func _on_AnimatedSprite_animation_finished():
	if ($AnimatedSprite.animation == 'hit'):
		queue_free()
