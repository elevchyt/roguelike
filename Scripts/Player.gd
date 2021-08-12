extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var Ray = $Area2D/RayCast2D
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var Area2D = $Area2D

var isPlayer = true
var hasPlayed = false
var active = false

# Activate function (when this unit enters its turn)
func activate():
	# Reset values
	active = true
	
func _process(delta):
	# Check if the player has the ability to take an action
	if (active == true):
		# Movement
		if (Input.is_action_just_pressed("key_w")):
			move_to_position(Vector2(0, -96))
		elif (Input.is_action_just_pressed("key_s")):
			move_to_position(Vector2(0, 96))
		elif (Input.is_action_just_pressed("key_a")):
			move_to_position(Vector2(-96, 0))
		elif (Input.is_action_just_pressed("key_d")):
			move_to_position(Vector2(96, 0))
	
func move_to_position(direction):
	# Cast the ray (for non-tilemap solid objects)
	Ray.set_cast_to(direction)
	Ray.force_raycast_update()
	
	# Check all tilemaps for wall at ray cast direction and move (index of wall is 0 in the tileset!)
	if (Ray.get_collider() == null):
		for tilemap in TileMapAStar.get_children():
			if (tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != 0 
			&& tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != -1):
				hasPlayed = true
				active = false
				
				# Move
				position = get_global_position() + direction
				
				# Animate Sprite
				#Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.1, Tween.EASE_IN, Tween.EASE_OUT)
				#Tween.start()
				
				# End Turn
				yield(get_tree().create_timer(0.2), "timeout") # a delay between button presses (must last more than tween!)
				end_turn()

# Go to next creature's turn
func end_turn():
	GameManager.calc_turn_order()
	GameManager.next_player_turn()
