extends Sprite

# Remove self after 1.2 seconds
func _ready():
	yield(get_tree().create_timer(1.2), "timeout")
	queue_free()
