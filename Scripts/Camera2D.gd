extends Camera2D

# Camera Shake
func shake(magnitude, frequency, duration):
	var durationCurrent = 0
	
	while (durationCurrent < duration):
		var randomOffset = Vector2(rand_range(-magnitude, magnitude), rand_range(-magnitude, magnitude))
		
		$Tween.interpolate_property(self, "offset", offset, randomOffset, frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		yield(get_tree().create_timer(frequency), "timeout")
		durationCurrent += frequency
		shake_reset(frequency)

func shake_reset(frequency):
	$Tween.interpolate_property(self, "offset", offset, Vector2.ZERO, frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()

# Example Shake
# shake(5, 0.01, 0.5)
