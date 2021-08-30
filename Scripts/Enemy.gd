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

# Status variables (poisoned, cursed etc.)
var cursed = false
var cursedCounter = 0
var poisoned = false
var poisonedCounter = 0
var playerWhoPoisonedMe
var ensnared = false
var ensnaredCounter = 0
var ensnareNode

# Moves next to target
func move(path):
	if (ensnared == false):
		var stepsCounter = 1 # normally happens when this unit's turn starts again!
		for step in path:
			if (stepsCounter > 0):
				stepsCounter -= 1
				position = step
	else:
		print('*** Cannot move ***')

# Activate function (when this unit enters it's turn)
func activate():
	# Check status (poison, curse etc.)
	status_check()
	
	# Find closest player & its path
	if (GameManager.players.empty() == false):
		var targetPlayer = GameManager.players[0]
		var path = TileMapAStar.find_path(get_global_position(), GameManager.players[0].get_global_position())
		var shortestPathSize = 999
		for player in GameManager.players:
			var currentPlayerPath = TileMapAStar.find_path(get_global_position(), player.get_global_position())
			if (currentPlayerPath.size() < shortestPathSize && player.invisible == false && player.invulnerable == false && player.state != 'dead' && player.state != 'dying'):
				targetPlayer = player
				path = TileMapAStar.find_path(get_global_position(), player.get_global_position())
				shortestPathSize = path.size()
		
		# Fix path
		path.remove(0) # remove the tile already on
		path.remove(path.size() - 1) # remove the tile that the target is on
		
		# Check if target is within attack range (for basic melee attack)
		var directions = [Vector2(0, -48), Vector2(0, 48), Vector2(-48, 0), Vector2(48, 0)]
		var targetInAttackRange = false
		for dir in directions:
			Ray.set_cast_to(dir)
			Ray.force_raycast_update()
			if (Ray.get_collider() != null):
				print(targetPlayer.name)
				print(targetPlayer.invulnerable)
				print(targetPlayer.invulnerableCounter)
				if (Ray.get_collider().get_parent() == targetPlayer && targetPlayer.invisible == false && targetPlayer.invulnerable == false && targetPlayer.state != 'dead' && targetPlayer.state != 'dying'):
					targetInAttackRange = true
					animation_attack(dir)
					attack(targetPlayer)
					
		# Check if target is within vision to move to it (optimally, must check with a raycast for "real" vision)
		if (path.size() <= visionRange && path.size() != 0 && targetPlayer.invisible == false && targetPlayer.state != 'dead' && targetPlayer.state != 'dying'):
			move(path)
		# If there is no path to the target
		elif (path.size() == 0 && targetInAttackRange == false):
			print('** IDLE (no path) **')
		# If target is out of vision range
		elif (path.size() > visionRange):
			print('** IDLE (no vision) **')
		
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
			target.state = 'dying'
			target.get_node('Sprite').modulate.a = 0.5
			GameManager.calc_turn_order()
		
		# Show damage text above target
		z_index = 3
		var damageText = GameManager.objDamageText.instance()
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
		z_index = 3
		var damageText = GameManager.objDamageText.instance()
		add_child(damageText)
		
		var randXOffset = ceil(rand_range(-48, 48))
		damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]miss[/color][/center]'
		damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]miss[/color][/center]'
		Tween.interpolate_property(damageText, "position", to_local(target.position) + Vector2(randXOffset, 0), to_local(target.position) + Vector2(randXOffset, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
		Tween.start()
		damageText.visible = true
		yield(get_tree().create_timer(1), "timeout")
		z_index = 2
		damageText.visible = false
		damageText.position = Vector2.ZERO

# Status Check (end turn)
# Decrement/Increment counters (curse, poison etc.)
func status_check():
	# Curse
	if (cursed == true && cursedCounter > 0):
		cursedCounter -= 1
		
		if (cursedCounter == 0):
			cursedCounter = 0
			cursed = false
			evasionPerc = evasionPercMax
			print('*** CURSE REMOVED ***')
	# Poison
	if (poisoned == true && poisonedCounter > 0):
		poisonedCounter -= 1
		
		# Damage Calculation
		var damageTotal = ceil(playerWhoPoisonedMe.intelligence / 2.0)
		
		# Reduce health
		health -= damageTotal
		
		# Check if killed & gain xp (check for level-up - for the player who poisoned this enemy)
		if (health <= 0):
			health = 0
			
			# Check for level-up
			playerWhoPoisonedMe.xpCurrent += level
			playerWhoPoisonedMe.level_up_check()
			
			# Destroy self
			queue_free()
			
		# Show damage text above target
		var damageText = GameManager.objDamageText.instance()
		add_child(damageText)
		
		z_index = 3
		damageText.get_node('TextDamage').bbcode_text = '[center][color=#c2d368]' + '-' + str(damageTotal) + '[/color][/center]'
		damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damageTotal) + '[/color][/center]'
		Tween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
		Tween.start()
		damageText.visible = true
		yield(get_tree().create_timer(1), "timeout") # DELAYS NEXT TURN, TOO
		z_index = 2
		damageText.visible = false
		damageText.position = Vector2.ZERO
		
		if (poisonedCounter == 0):
			poisonedCounter = 0
			playerWhoPoisonedMe = null
			poisoned = false
			print('*** POISON REMOVED ***')
	# Ensnared
	if (ensnared == true && ensnaredCounter > 0):
		ensnaredCounter -= 1
		
		if (ensnaredCounter == 0):
			ensnaredCounter = 0
			ensnared = false
			ensnareNode.queue_free()
			evasionPerc = evasionPercMax
			print('*** ENSNARED REMOVED ***')
##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
