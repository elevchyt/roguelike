extends TextureProgress

# Re-calculates min, max & current health
func _process(delta):
	max_value = get_parent().get_parent().healthMax
	value = get_parent().get_parent().health
