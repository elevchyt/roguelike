extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var Ray = $Area2D/RayCast2D
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var Area2D = $Area2D
onready var healthBar = get_node('HealthBar/HealthBar')

var isPlayer = true
var isMonster = false
var hasPlayed = false
var active = false
var state = 'alive' # alive, dead, sleep, stun, root

var targetMode = false # true when using targeted skills

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
onready var xpToLevel = ceil(10 + level * 2)
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
			$Target/TargetSprite.animation = "target_blue"
		"pink":
			$CursorSprite.animation = "cursor_pink"
			$Target/TargetSprite.animation = "target_pink"
		"orange":
			$CursorSprite.animation = "cursor_orange"
			$Target/TargetSprite.animation = "target_orange"
	
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
	if (active == true && targetMode == false):
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
	var damageTotal = strength + weaponDamage
	target.health -= damageTotal
	print(str(target.health) + ' / ' + str(target.healthMax))
	
	# Show damage text above target
	var damageText = target.get_node('TextDamage')
	
	damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]' + '-' + str(damageTotal) + '[/color][/center]'
	damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damageTotal) + '[/color][/center]'
	Tween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	damageText.visible = true
	yield(get_tree().create_timer(1), "timeout") # DELAYS NEXT TURN, TOO
	damageText.visible = false
	damageText.position = Vector2.ZERO
	
	# Check if killed & gain xp (check for level-up)
	if (target.health <= 0):
		# Check for level-up
		xpCurrent += target.level
		level_up_check()
			
		# Destroy target
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

# Level-Up
func level_up_check():
	while (xpCurrent >= xpToLevel):
		# Level-Up Text
		$TextLevelUp.get_node("TextLevelUp").bbcode_text = '[center]Level-Up![/center]'
		$TextLevelUp.get_node('TextLevelUpShadow').bbcode_text = '[center][color=#ff212123]Level-Up![/color][/center]'
		Tween.interpolate_property($TextLevelUp, "position", Vector2.ZERO, Vector2(0, -96), 0.5, Tween.EASE_IN, Tween.EASE_OUT)
		Tween.start()
		$TextLevelUp.visible = true
		
		print('*** LEVEL-UP! ***')
		
		# XP
		xpCurrent = xpCurrent - xpToLevel
		level += 1
		healthMax = ceil(5 + strength * 1.2 + level * 2)
		manaMax = ceil(5 + intelligence * 1.2 + level * 2)
		xpToLevel = ceil(10 + level * 2)
		
		# Raise stats based on class
		match playerClass:
			"Warrior":
				strength += 2
				dexterity += 1
				intelligence += 1
			"Rogue":
				strength += 1
				dexterity += 2
				intelligence += 1
			"Mage":
				strength += 1
				dexterity += 1
				intelligence += 2
			"Priest":
				strength += 1
				dexterity += 1
				intelligence += 2
			"Monk":
				strength += 2
				dexterity += 1
				intelligence += 1
		
	# Reset text
	yield(get_tree().create_timer(1.2), "timeout") # DELAYS NEXT TURN, TOO
	$TextLevelUp.visible = false
	$TextLevelUp.position = Vector2.ZERO

##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
