extends AnimatedSprite

onready var Player = get_parent().get_parent()

# Set target animation & color based on skillInVision state
func _process(delta):
	if (Player.skillInVision == true):
		# Target color
		match Player.playerColor:
			"blue":
				animation = "target_blue"
			"pink":
				animation = "target_pink"
			"orange":
				animation = "target_orange"
	else:
		animation = 'target_no_vision'
