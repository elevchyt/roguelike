extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var Ray = $Area2D/RayCast2D
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var Area2D = $Area2D

var isPlayer = true
var isMonster = false
var hasPlayed = false
var active = false
var state = 'alive' # alive, dead, sleep, stun, root

# Stats
var level = 1
var strength = 1
var dexterity = 1
var intelligence = 1
onready var healthMax = ceil(5 + strength * 1.2 + level * 2)
onready var health = healthMax
onready var manaMax = ceil(5 + intelligence * 1.2 + level * 2)
onready var mana = manaMax
var xpCurrent = 0
onready var xpToLevel = ceil(5 + level * 2)
onready var evasionPerc = dexterity * 1.4 # clamp to 40% (0.4)
var weaponDamage = 0

# Sprites
export(String, "Warrior", "Mage", "Rogue", "Priest", "Monk") var playerClass
export(String, "blue", "pink", "orange") var playerColor

# Initialize object
func _ready():
	# Class Sprite, Colors & Starting Stats
	match playerClass:
		"Warrior":
			strength = 6
			dexterity = 3
			intelligence = 1
			
			match playerColor:
				"blue":
					$Sprite.texture = load("res://Sprites/warrior_blue.png")
				"pink":
					$Sprite.texture = load("res://Sprites/warrior_pink.png")
				"orange":
					$Sprite.texture = load("res://Sprites/warrior_orange.png")
		"Mage":
			strength = 3
			dexterity = 2
			intelligence = 5
			
			match playerColor:
				"blue":
					$Sprite.texture = load("res://Sprites/mage_blue.png")
				"pink":
					$Sprite.texture = load("res://Sprites/mage_pink.png")
				"orange":
					$Sprite.texture = load("res://Sprites/mage_orange.png")
		"Rogue":
			strength = 3
			dexterity = 4
			intelligence = 3
			
			match playerColor:
				"blue":
					$Sprite.texture = load("res://Sprites/rogue_blue.png")
				"pink":
					$Sprite.texture = load("res://Sprites/rogue_pink.png")
				"orange":
					$Sprite.texture = load("res://Sprites/rogue_orange.png")
		"Priest":
			strength = 2
			dexterity = 2
			intelligence = 6
			
			match playerColor:
				"blue":
					$Sprite.texture = load("res://Sprites/priest_blue.png")
				"pink":
					$Sprite.texture = load("res://Sprites/priest_pink.png")
				"orange":
					$Sprite.texture = load("res://Sprites/priest_orange.png")
		"Monk":
			strength = 5
			dexterity = 4
			intelligence = 1
			
			match playerColor:
				"blue":
					$Sprite.texture = load("res://Sprites/monk_blue.png")
				"pink":
					$Sprite.texture = load("res://Sprites/monk_pink.png")
				"orange":
					$Sprite.texture = load("res://Sprites/monk_orange.png")
					
	# Cursor color
	match playerColor:
		"blue":
			$CursorSprite.animation = "cursor_blue"
		"pink":
			$CursorSprite.animation = "cursor_pink"
		"orange":
			$CursorSprite.animation = "cursor_orange"
	
	# Re-Calculate HP, MP & Evasion based on mana
	healthMax = ceil(5 + strength * 1.2 + level * 2)
	manaMax = ceil(5 + intelligence * 1.2 + level * 2)
	evasionPerc = dexterity * 1.4
	health = healthMax
	mana = manaMax

# Activate function (when this unit enters its turn)
func activate():
	# If dead skip turn
	if (state == 'dead'):
		end_turn()
	
	# Reset values
	active = true
	
	# Activate cursor (selector on top of sprite's head)
	$CursorSprite.visible = true
	
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
		elif (Input.is_action_just_pressed("key_escape")):
			end_turn()

# Move To Position
func move_to_position(direction):
	# Cast the ray (for non-tilemap solid objects)
	Ray.set_cast_to(direction)
	Ray.force_raycast_update()
	
	# Check all tilemaps for wall at ray cast direction and move (index of wall is 0 in the tileset!)
	if (Ray.get_collider() == null):
		for tilemap in TileMapAStar.get_children():
			if (tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != 0 
			&& tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != -1):
				# Move
				position = get_global_position() + direction
				
				# Animate Sprite
				#Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.1, Tween.EASE_IN, Tween.EASE_OUT)
				#Tween.start()
				
				# End Turn
				end_turn()
				
	# Attack (if monster is at position)
	elif (Ray.get_collider().get_parent().isMonster == true):
		animation_attack(direction)
		attack(Ray.get_collider().get_parent())

# Attack
func attack(target):
	hasPlayed = true
	active = false
	
	# Reduce health
	target.health -= strength + weaponDamage
	print(str(target.health) + ' / ' + str(target.healthMax))
	
	# Check if killed
	if (target.health <= 0):
		target.queue_free()
	
	# End Turn
	end_turn()

# Go to next creature's turn
func end_turn():
	hasPlayed = true
	active = false
	
	# Delay between button presses (must last more than tweens!)
	yield(get_tree().create_timer(0.2), "timeout") 
	
	# Hide Cursor
	$CursorSprite.visible = false
	
	# End Turn
	GameManager.calc_turn_order()
	GameManager.next_player_turn()

##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
