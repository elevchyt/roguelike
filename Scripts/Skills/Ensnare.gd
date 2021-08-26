extends Node2D

onready var CameraNode = get_node("/root/World/Camera2D")
onready var Root = get_node("/root/World/")

# Run hit animation on target destination arrival
func _process(delta):
	yield(get_tree().create_timer(0.6), "timeout")
	#Root.add_child(self)
	CameraNode.shake(3, 0.02, 0.1)
		
	# Reset rotation & change animation
	$AnimatedSprite.rotation = 0
	$AnimatedSprite.animation = 'hit'
	$AnimatedSprite.speed_scale = 2.5
