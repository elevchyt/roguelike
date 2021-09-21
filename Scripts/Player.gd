extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var Ray = $Area2D/RayCastMovement
onready var RayTarget = $RayCastVision
onready var Target = $Target
onready var PlayerSkills = $PlayerSkills
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var Area2D = $Area2D
onready var healthBar = get_node('HealthBar/HealthBar')
onready var HUD = get_node("/root/World/HUD")

var isPlayer = true
var isMonster = false
var hasPlayed = false
var active = false
var state = 'alive' # alive, dead, dying
var dyingCounter = 5 # dies on 5th turn

# Items / Inventory
var items : Array # Current items in inventory (strings)
var itemsDescription : Array # Curernt items' descriptions
var itemsType : Array # Current items' type (consumable, equipment, misc)
var itemsState : Array # Current items' state (equipped, unequipped)
var inventoryMode = false # true when pressing inventory button (Tab)
var itemChoose : String # Current highlighted item
var itemChooseIndex : Array # Index of current highlighted item

var weaponSlot : String # Equip slot for weapon
var armorSlot : String # Equip slot for armor

# Skills
var skills : Array # Array of current skills
var skillsDescription : Array # Array of skills' descriptions
var skillsType : Array # Array of skills' type
var skillsCooldown : Array # Array of skills' cooldown
var skillsCooldownCurrent = [0, 0, 0, 0] # Array of skills' cooldown (counter)
var skillsManaCost : Array # Array of skills' mana cost
var skillsRange : Array # Array of skills' range
var skillsTargetType : Array # Array of skills' target type
var skillsClass : Array # Array of total class skills
var skillSlots : Array # Array of skill slot sprite nodes
var skillMode = false # true when pressing skill choose button (Left-Shift)
var skillChoose : String # The current skill highlighted before usage; during skillMode
var skillChooseIndex : int # index of current highlighted skill
var targetMode = false # true when using targeted skills
var skillInVision = true # to check if the current position of the target is within vision (e.g. the player has a clear shot)

# Warrior variables
var cleave = false
var cleaveChancePerc = 50
var execute = false

# Mage variables
var arcaneShield = false

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
onready var evasionPerc = clamp(dexterity * 1.4, 0, 50) # clamp to 50%
var weaponDamage = 0
var damageResistance = 0

# Status variables (poisoned, cursed etc.)
var cursed = false
var cursedCounter = 0
var poisoned = false
var poisonedCounter = 0
var creatureWhoPoisonedMe
var ensnared = false
var ensnaredCounter = 0
var ensnareNode
var invisible = false
var invisibleCounter = 0
var invulnerable = false
var invulnerableCounter = 0
var retaliation = false
var retaliationCounter = 0
var retaliationNode

# Sprites
export(String, "Warrior", "Mage", "Rogue", "Priest", "Monk") var playerClass
export(String, "blue", "pink", "orange") var playerColor

# Initialize object
func _ready():
	# RayCast (target) initial settings
	RayTarget.add_exception($Area2D)
	RayTarget.add_exception($Target)
	
	# Assign skill slot sprites
	skillSlots.append(HUD.get_node('Skill1'))
	skillSlots.append(HUD.get_node('Skill2'))
	skillSlots.append(HUD.get_node('Skill3'))
	skillSlots.append(HUD.get_node('Skill4'))
	
	# Class Sprite, Colors & Starting Stats
	match playerClass:
		"Warrior":
			strength = 6
			dexterity = 3
			intelligence = 1
			
			skillsClass.append('Cleave')
			skillsClass.append('Retaliation')
			skillsClass.append('Execute')
			
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
			
			skillsClass.append('Flare')
			skillsClass.append('Thunderclap')
			skillsClass.append('Arcane Shield')
			skillsClass.append('Curse')
			
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
			
			skillsClass.append('Poison Dart')
			skillsClass.append('Ensnare')
			skillsClass.append('Leap')
			skillsClass.append('Shadow Walk')
			
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
			
			skillsClass.append('Healing Prayer')
			skillsClass.append('Purify')
			skillsClass.append('Divine Shield')
			skillsClass.append('Ressurect')
			
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
					
	# Cursor & Target color
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
	evasionPerc =  clamp(dexterity * 1.4, 0, 50)
	health = healthMax
	mana = manaMax

# Activate function (when this unit enters its turn)
func activate():
	# Check status (poison, curse, passives etc.)
	status_check()
	
	# Reset values
	active = true
	
	# Activate cursor (selector on top of sprite's head)
	$CursorSprite.visible = true
	
	# Refresh skills toolbar
	var skillsArraySize = skills.size()
	var i = 0 # counter
	for slot in skillSlots:
		# Make slots empty first
		slot.set_texture(load('res://Sprites/skill_slot.png'))
	
		# Set correct slot sprites from GameManager skillSlotSprites (if not empty)
		if (skills.empty() == false && skillsArraySize > i):
			var index = GameManager.skillsNames.find(skills[i])
			slot.texture = load(GameManager.skillsSlotSprites[index])
			
		i += 1 # counter increment

# GET INPUT
func _process(delta):
	# TEST
	if (active == true && targetMode == false && skillMode == false):
		# Level up debug (home key gives 1 level)
		if (Input.is_action_just_pressed("key_home")):
			xpCurrent = xpToLevel
			level_up_check()
	
	# Check if the player has the ability to take an action
	if (active == true && targetMode == false && skillMode == false && inventoryMode == false):
		# Movement
		if (Input.is_action_just_pressed("key_w")):
			move_to_position(Vector2(0, -96))
		elif (Input.is_action_just_pressed("key_s")):
			move_to_position(Vector2(0, 96))
		elif (Input.is_action_just_pressed("key_a")):
			move_to_position(Vector2(-96, 0))
		elif (Input.is_action_just_pressed("key_d")):
			move_to_position(Vector2(96, 0))
			
		# Skip turn
		elif (Input.is_action_just_pressed("key_ctrl")):
			end_turn()
		
		# Inventory
		elif (Input.is_action_just_pressed("key_tab")):
			inventoryMode = true
			
			HUD.get_node('Tween').stop_all()
			HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", Vector2(0, 0), Vector2(0, -192), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
			HUD.get_node('TweenTextTooltip').start()
			HUD.get_node('Tween').start()
			HUD.get_node('Inventory').visible = true
		# Skills
		elif (Input.is_action_just_pressed("key_shift") && skills.empty() == false && inventoryMode == false):
			skillMode = true
			
			skillChooseIndex = 0
			skillChoose = skills[skillChooseIndex]
			
			HUD.get_node('Tween').stop_all()
			HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", scale, scale * 1.4, 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT )
			HUD.get_node('Tween').start()
			HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", Vector2(0, 0), Vector2(0, -192), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
			HUD.get_node('TweenTextTooltip').start()
			HUD.get_node('SkillDetails/SkillTitle').bbcode_text = '[center]' + skills[skillChooseIndex] + '[/center]'
			HUD.get_node('SkillDetails/SkillTitleShadow').bbcode_text = '[center][color=#ff212123]' + skills[skillChooseIndex] + '[/color][/center]'
			HUD.get_node('SkillDetails/SkillDescription').bbcode_text = skillsDescription[skillChooseIndex]
			HUD.get_node('SkillDetails/SkillDescriptionShadow').bbcode_text = '[color=#ff212123]' + skillsDescription[skillChooseIndex] + '[/color]'
			HUD.get_node('SkillDetails/SkillCostCooldown').bbcode_text = '[center]- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/center]'
			HUD.get_node('SkillDetails/SkillCostCooldownShadow').bbcode_text = '[center][color=#ff212123]' + '- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/color][/center]'
			HUD.get_node('SkillDetails').visible = true
	# Skills mode scroll 
	# Right
	elif (skillMode == true && Input.is_action_just_pressed("key_d") && skillChooseIndex < skills.size() - 1):
		skillChooseIndex += 1
		skillChoose = skills[skillChooseIndex]

		skillSlots[skillChooseIndex].z_index = 1
		skillSlots[skillChooseIndex - 1].z_index = 0
		
		HUD.get_node('Tween').stop_all()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", scale, scale * 1.4, 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex - 1], "scale", scale * 1.4, scale, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('SkillDetails/SkillTitle').bbcode_text = '[center]' + skills[skillChooseIndex] + '[/center]'
		HUD.get_node('SkillDetails/SkillTitleShadow').bbcode_text = '[center][color=#ff212123]' + skills[skillChooseIndex] + '[/color][/center]'
		HUD.get_node('SkillDetails/SkillDescription').bbcode_text = skillsDescription[skillChooseIndex]
		HUD.get_node('SkillDetails/SkillDescriptionShadow').bbcode_text = '[color=#ff212123]' + skillsDescription[skillChooseIndex] + '[/color]'
		HUD.get_node('SkillDetails/SkillCostCooldown').bbcode_text = '[center]- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/center]'
		HUD.get_node('SkillDetails/SkillCostCooldownShadow').bbcode_text = '[center][color=#ff212123]' + '- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/color][/center]'
	# Left
	elif (skillMode == true && Input.is_action_just_pressed("key_a") && skillChooseIndex > 0):
		skillChooseIndex -= 1
		skillChoose = skills[skillChooseIndex]

		skillSlots[skillChooseIndex].z_index = 1
		skillSlots[skillChooseIndex + 1].z_index = 0
		
		HUD.get_node('Tween').stop_all()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", scale, scale * 1.4, 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex + 1], "scale", scale * 1.4, scale, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('SkillDetails/SkillTitle').bbcode_text = '[center]' + skills[skillChooseIndex] + '[/center]'
		HUD.get_node('SkillDetails/SkillTitleShadow').bbcode_text = '[center][color=#ff212123]' + skills[skillChooseIndex] + '[/color][/center]'
		HUD.get_node('SkillDetails/SkillDescription').bbcode_text = skillsDescription[skillChooseIndex]
		HUD.get_node('SkillDetails/SkillDescriptionShadow').bbcode_text = '[color=#ff212123]' + skillsDescription[skillChooseIndex] + '[/color]'
		HUD.get_node('SkillDetails/SkillCostCooldown').bbcode_text = '[center]- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/center]'
		HUD.get_node('SkillDetails/SkillCostCooldownShadow').bbcode_text = '[center][color=#ff212123]' + '- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/color][/center]'
	# Cancel Skills
	elif (skillMode == true && Input.is_action_just_pressed("key_escape")):
		skillMode = false
		
		# Leave skills toolbar
		HUD.get_node('Tween').stop_all()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", scale * 1.4, scale, 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT )
		HUD.get_node('Tween').start()
		HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", Vector2(0, -192), Vector2(0, 0), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		HUD.get_node('TweenTextTooltip').start()
		HUD.get_node('SkillDetails').visible = false
	# Cancel Inventory
	elif (inventoryMode == true && Input.is_action_just_pressed("key_escape")):
		inventoryMode = false
		
		# Leave inventory
		HUD.get_node('Tween').stop_all()
		HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", Vector2(0, -192), Vector2(0, 0), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		HUD.get_node('TweenTextTooltip').start()
		HUD.get_node('Inventory').visible = false
	# Cancel Target (leaves from targetMode AND skillMode)
	elif (targetMode == true && Input.is_action_just_pressed("key_escape")):
		targetMode = false
		skillInVision = true
		
		# Leave skills toolbar
		HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
		skillSlots[skillChooseIndex].scale = Vector2(1, 1)
		skillSlots[skillChooseIndex].modulate.a = 1
		
		# Disable target
		$Target.visible = false
		$Target/CollisionShape2D.disabled = true
		$Target.position = Vector2.ZERO
		
		# Reset RayCast
		RayTarget.set_cast_to($Target.position)
		RayTarget.force_raycast_update()
	# Choose
	elif (skillMode == true && Input.is_action_just_pressed("key_space")):
		# Check for mana cost & cooldown first
		if (mana >= skillsManaCost[skillChooseIndex] && skillsCooldownCurrent[skillChooseIndex] <= 0):
			# Target Skills => Enemy OR Friendly OR Floor
			if (skillsType[skillChooseIndex] == 'active' 
			&& (skillsTargetType[skillChooseIndex] == 'target+enemy' 
			|| skillsTargetType[skillChooseIndex] == 'target+friendly'
			|| skillsTargetType[skillChooseIndex] == 'target+floor')):
				skillMode = false
				targetMode = true
				
				# Highlight skill on toolbar
				skillSlots[skillChooseIndex].scale = Vector2(1.4, 1.4)
				skillSlots[skillChooseIndex].modulate.a = 0.8
				
				# Enable target
				$Target.visible = true
				$Target/CollisionShape2D.disabled = false
			# around+enemy
			elif (skillsType[skillChooseIndex] == 'active' 
			&& skillsTargetType[skillChooseIndex] == 'around+enemy'):
				skillMode = false
				
				# Highlight skill on toolbar
				skillSlots[skillChooseIndex].scale = Vector2(1.4, 1.4)
				skillSlots[skillChooseIndex].modulate.a = 0.8
				
				# Use skill instantly (no target)
				$PlayerSkills.use_skill(skills[skillChooseIndex])
			# self
			elif (skillsType[skillChooseIndex] == 'active' 
			&& skillsTargetType[skillChooseIndex] == 'self'):
				skillMode = false
				
				# Highlight skill on toolbar
				skillSlots[skillChooseIndex].scale = Vector2(1.4, 1.4)
				skillSlots[skillChooseIndex].modulate.a = 0.8
				
				# Use skill instantly on self(no target)
				$PlayerSkills.use_skill(skills[skillChooseIndex])
		# Show feedback message for not enough mana
		elif(mana < skillsManaCost[skillChooseIndex]):
			HUD.get_node('FeedbackTextMana').visible = true
			yield(get_tree().create_timer(1.2), "timeout")
			HUD.get_node('FeedbackTextMana').visible = false
		# Show feedback message for skill on cooldown
		else:
			HUD.get_node('FeedbackTextCooldown').visible = true
			yield(get_tree().create_timer(1.2), "timeout")
			HUD.get_node('FeedbackTextCooldown').visible = false
	# Move Target
	elif (targetMode == true):
		if (Input.is_action_just_pressed("key_w")):
			move_target(Vector2(0, -96))
		elif (Input.is_action_just_pressed("key_s")):
			move_target(Vector2(0, 96))
		elif (Input.is_action_just_pressed("key_a")):
			move_target(Vector2(-96, 0))
		elif (Input.is_action_just_pressed("key_d")):
			move_target(Vector2(96, 0))
		elif (Input.is_action_just_pressed("key_space")):
			if (skillInVision == true):
				$PlayerSkills.use_skill(skills[skillChooseIndex])

######## END OF INPUT ########
################################################################################################################
# Move To Position
func move_to_position(direction):
	# Cast the ray (for non-tilemap solid objects)
	Ray.set_cast_to(direction)
	Ray.force_raycast_update()
	
	# Check all tilemaps for wall at ray cast direction and move (index of wall is 0 in the tileset!)
	if (Ray.get_collider() == null):
		for tilemap in TileMapAStar.get_children():
			if (tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != -1):
				# Move
				position += direction
				
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
	
	# Check if hit is successful (evasion)
	var hitChance = randi() % 100
	if (hitChance > target.evasionPerc):
		# Cleave check
		PlayerSkills.cleave_check(target)
		
		# (Warrior) Check for execute
		var executeChance = randi() % 100
		print(executeChance)
		print(target.health)
		print(target.healthMax)
		if (execute == true && executeChance <= 25 && target.health <= target.healthMax * 0.3):
			# Camera Shake
			CameraNode.shake(2, 0.02, 0.2)
			
			# Reduce health to 0
			target.health = 0
			
			# Show executed text (independent on player)
			var executedText = GameManager.objStatusTextIndependent.instance()
			executedText.position = to_local(target.position)
			add_child(executedText)
			
			z_index = 3
			executedText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]executed[/color][/center]'
			executedText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]executed[/color][/center]'
			Tween.interpolate_property(executedText, "position", to_local(target.position), to_local(target.position) + Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
			Tween.start()
			
			# Check if killed & gain xp (check for level-up)
			if (target.health <= 0):
				target.health = 0
				
				# Check for level-up
				xpCurrent += target.level
				level_up_check()
				
				# Destroy target
				target.queue_free()
		# Normal Attack
		else:
			# Reduce health
			var damageTotal = strength + weaponDamage - target.damageResistance
			
			if (target.cursed == true):
				damageTotal = damageTotal * 1.2
			if (invisible == true):
				damageTotal = damageTotal + ceil((dexterity + 2) / 3)
			
			if (damageTotal < 0):
				damageTotal = 0
			target.health -= damageTotal
			
			# Show damage text
			GameManager.createDamageText(target, damageTotal, '#ffffff')
			
			# Check if killed & gain xp (check for level-up)
			if (target.health <= 0):
				target.health = 0
				
				# Check if ensnared == true to remove ensnareNode on death
				if (target.ensnared == true):
					target.ensnareNode.queue_free()
				
				# Check for level-up
				xpCurrent += target.level
				level_up_check()
				
				# Destroy target
				target.queue_free()
	# Show miss text above target
	else:
		GameManager.createStatusText(target, 'MISS', '#ffffff')
	
	# (Rogue) Remove invisibility
	if (invisible == true):
		invisible = false
		invisibleCounter = 0
		$Sprite.modulate = Color(1, 1, 1, 1)
	
	# End Turn
	end_turn()

# Move Target
func move_target(direction):
	# Get path and move to next position
	var path = TileMapAStar.find_path_skill(to_global($Target.position), position)
	var pathSize = path.size()
	
	for tilemap in TileMapAStar.get_children():
		if (tilemap.get_cellv(tilemap.world_to_map(to_global($Target.position) + direction)) != -1):
			if (skillsRange[skillChooseIndex] >= pathSize):
				$Target.position += direction
				
				# Cast a ray to check if skillInVision is true
				RayTarget.set_cast_to($Target.position)
				RayTarget.force_raycast_update()
				
				skillInVision = true
				if (RayTarget.get_collider() != null):
					# Walls
					if(RayTarget.get_collider() is TileMap):
						skillInVision = false # is used when skill is casted to either cast OR deny casting because of vision
						print('** target not within vision **')
					if(RayTarget.get_collider() is TileMap):
						skillInVision = false # is used when skill is casted to either cast OR deny casting because of vision
						print('** target not within vision **')
					# Target visible
					else:
						skillInVision = true
						print('** target is within vision **')
			else:
				$Target.position = Vector2.ZERO
				skillInVision = true
				
				RayTarget.set_cast_to($Target.position)
				RayTarget.force_raycast_update()

# Go to next creature's turn
func end_turn():
	hasPlayed = true
	active = false
	skillMode = false
	targetMode = false
	
	# Decrement all cooldown counters by 1
	for i in range(skillsCooldownCurrent.size()):
		if (skillsCooldownCurrent[i] > 0):
			skillsCooldownCurrent[i] -= 1
	
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
		xpToLevel = ceil(10 + level * 2)
		
		print(evasionPerc)
		
		
		# Add skills
		match level:
			2:
				add_skill(skillsClass[0])
			5:
				add_skill(skillsClass[1])
			8:
				add_skill(skillsClass[2])
			12:
				add_skill(skillsClass[3])
				
		# Raise stats & check passives for skills just added
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
				
		# Change stats based on STR, DEX, INT increase
		healthMax = ceil(5 + strength * 1.2 + level * 2)
		manaMax = ceil(5 + intelligence * 1.2 + level * 2)
		health = healthMax
		mana = manaMax
		evasionPerc = clamp(dexterity * 1.4, 0, 50)
	# Reset text
	yield(get_tree().create_timer(2), "timeout") # DELAYS NEXT TURN, TOO
	$TextLevelUp.visible = false
	$TextLevelUp.position = Vector2.ZERO

# Gives a skill to the player
func add_skill(skillName):
	for slot in skillSlots:
		if (slot.texture.resource_path == 'res://Sprites/skill_slot.png'):
			# Add skill data & set skill sprite
			var index = GameManager.skillsNames.find(skillName)
			slot.texture = load(GameManager.skillsSlotSprites[index])
			
			skills.append(GameManager.skillsNames[index])
			skillsDescription.append(GameManager.skillsDescription[index])
			skillsCooldown.append(GameManager.skillsCooldown[index])
			skillsManaCost.append(GameManager.skillsManaCost[index])
			skillsRange.append(GameManager.skillsRange[index])
			skillsType.append(GameManager.skillsType[index])
			skillsTargetType.append(GameManager.skillsTargetType[index])
			
			# Animation
			HUD.get_node('Tween').interpolate_property(slot, "scale", scale, scale * 1.5, 1.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			HUD.get_node('Tween').start()
			yield(get_tree().create_timer(1.3), "timeout")
			HUD.get_node('Tween').interpolate_property(slot, "scale", scale * 1.5, scale, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			HUD.get_node('Tween').start()
			
			break # stop searching

# Check status (poison, curse etc.)
func status_check():
	var index
	
	# Arcane Shield
	if (mana >= ceil(manaMax / 2) && skills.find('Arcane Shield') != -1):
		arcaneShield = true
	else:
		arcaneShield = false
	
	# Cleave
	if (skills.find('Cleave') != -1):
		cleave = true
	else:
		cleave = false
		
	# Execute
	if (skills.find('Execute') != -1):
		execute = true
	else:
		execute = false
		
	# Check retaliation counter (Warrior only)
	if (retaliation == true):
		retaliationCounter -= 1
		
		if (retaliationCounter == 0):
			retaliationCounter = 0
			retaliation = false
			retaliationNode.queue_free()
		
	# Check leap range (Rogue only)
	index = skills.find('Leap')
	if (index != -1):
		skillsRange[index] = clamp(ceil(dexterity / 8.0), 0, 10)
		
	# Check shadow walk duration (Rogue only) (Uses range for duration)
	index = skills.find('Shadow Walk')
	if (index != -1):
		skillsRange[index] = ceil(dexterity / 3.0)

	# Check shadow walk counter (Rogue only)
	if (invisible == true):
		invisibleCounter -= 1
		
		if (invisibleCounter == 0):
			invisibleCounter = 0
			invisible = false
			$Sprite.modulate = Color(1, 1, 1, 1)

	# Check invulnerability
	if (invulnerable == true):
		invulnerableCounter -= 1
		
		if (invulnerableCounter == 0):
			invulnerableCounter = 0
			invulnerable = false
##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
