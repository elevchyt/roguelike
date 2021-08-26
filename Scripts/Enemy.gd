extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var Ray = $Area2D/RayCast2D
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var healthBar = get_node('HealthBar/HealthBar')

export(int) var visionRange = 3 # the number of steps where this unit will become aggressive towards the player
var isPlayer = false
var isMonster = true
var hasPlayed = false

# Stats
export(int) var level
export(int) var strength
export(int) var dexterity
export(int) var intelligence
export(int) var damageResistance
onready var healthMax = ceil(strength * 1.2 + level * 2)
onready var health = healthMax
onready var manaMax = ceil(intelligence * 1.2 + level * 2)
onready var mana = manaMax
onready var evasionPerc = clamp(dexterity * 1.4, 0, 50) # clamp to 50%
onready var evasionPercMax = clamp(dexterity * 1.4, 0, 50) # clamp to 50% (used to reset evasion after curse, ensnare etc.)

# Mage Variables on enemies
var cursed = false
var cursedCounter = 0

# Moves next to target
func move(path):
	var stepsCounter = 1 # normally happens when this unit's turn starts again!
	for step in path:
		if (stepsCounter > 0):
			stepsCounter -= 1
			position = step

# Activate function (when this unit enters it's turn)
func activate():
	print('-------------------')
	print(damageResistance)
	print(evasionPerc)
	print('-------------------')
	# Find closest player & its path
	if (GameManager.players.empty() == false):
		var targetPlayer = GameManager.players[0]
		var path = TileMapAStar.find_path(get_global_position(), GameManager.players[0].get_global_position())
		var shortestPathSize = path.size()
		for player in GameManager.players:
			var currentPlayerPath = TileMapAStar.find_path(get_global_position(), player.get_global_position())
			if (currentPlayerPath.size() < shortestPathSize):
				targetPlayer = player
				path = TileMapAStar.find_path(get_global_position(), player.get_global_position())
				shortestPathSize = path.size()
		
		# Fix path
		path.remove(0) # remove the tile already on
		path.remove(path.size() - 1) # remove the tile that the target is on
		
		print('-Distance to target from ' + name + ': ' + str(path.size()))
		# Check if target is within attack range (for basic melee attack)
		var directions = [Vector2(0, -48), Vector2(0, 48), Vector2(-48, 0), Vector2(48, 0)]
		var targetInAttackRange = false
		for dir in directions:
			Ray.set_cast_to(dir)
			Ray.force_raycast_update()
			if (Ray.get_collider() != null):
				if (Ray.get_collider().get_parent() == targetPlayer):
					targetInAttackRange = true
					animation_attack(dir)
					attack(targetPlayer)
					print('** ATTACK **') # attack action
					
		# Check if target is within vision to move to it (optimally, must check with a raycast for "real" vision)
		if (path.size() <= visionRange && path.size() != 0):
			move(path)
		# If there is no path to the target
		elif (path.size() == 0 && targetInAttackRange == false):
			print('** IDLE (no path) **')
		# If target is out of vision range
		elif (path.size() > visionRange):
			print('** IDLE (no vision) **')
			
		# Decrement/Increment counters (curse, poison etc.)
		# Curse
		if (cursed == true && cursedCounter > 0):
			cursedCounter -= 1
			
			if (cursedCounter == 0):
				cursedCounter = 0
				cursed = false
				evasionPerc = evasionPercMax
				print('*** CURSE REMOVED ***')
		
		# END TURN
		hasPlayed = true

# Attack
func attack(target):
	# Check if hit successful
	var hitChance = randi() % 100
	if (hitChance > target.evasionPerc):
		# Damage Calculation (check for shields first)
		var damageTotal
		if (target.arcaneShield == true):
			damageTotal = ceil(strength * 0.8) - target.damageResistance
		else:
			damageTotal = ceil(strength) - target.damageResistance
			
		if (damageTotal < 0):
			damageTotal = 0
		
		# Reduce target health
		target.health -= damageTotal
		
		# Check if killed & remove from players array & set his state to dead
		if (target.health <= 0):
			target.health = 0
			target.state = 'dead'
			target.get_node('Sprite').modulate.a = 0.5
			GameManager.calc_turn_order()
		
		# Show damage text above target
		z_index = 3
		var damageText = GameManager.objDamageText.instance()
		print(damageText.position)
		print(target.position)
		add_child(damageText)
		
		var randXOffset = ceil(rand_range(-48, 48))
		damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]' + '-' + str(damageTotal) + '[/color][/center]'
		damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damageTotal) + '[/color][/center]'
		Tween.interpolate_property(damageText, "position", to_local(target.position) + Vector2(randXOffset, 0), to_local(target.position) + Vector2(randXOffset, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
		Tween.start()
		damageText.visible = true
		yield(get_tree().create_timer(1), "timeout")
		z_index = 2
		damageText.visible = false
		damageText.position = Vector2.ZERO
	# Show miss text above target
	else:
		z_index = 1
		var damageText = target.get_node('TextDamage')
		damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]MISS[/color][/center]'
		damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]MISS[/color][/center]'
		Tween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
		Tween.start()
		damageText.visible = true
		yield(get_tree().create_timer(1), "timeout")
		z_index = 0
		damageText.visible = false
		damageText.position = Vector2.ZERO

##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
