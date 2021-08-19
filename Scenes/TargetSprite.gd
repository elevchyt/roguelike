extends AnimatedSprite

onready var Player = get_parent().get_parent()
onready var defaultTarget = animation

# Set target animation & color based on skillInVision state
func _process(delta):
	if (Player.skillInVision == true):
		animation = defaultTarget
	else:
		animation = 'target_no_vision'
