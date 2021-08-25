extends TextureProgress

# Re-calculates max health (in-case of level up) (MUST HAPPEN IN LEVEL UP!)
func _process(delta):
	max_value = get_parent().get_parent().healthMax
	value = get_parent().get_parent().health
