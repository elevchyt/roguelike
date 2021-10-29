extends Node2D

onready var RootNode = get_node("/root/World")
onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var RayMovement = $Area2D/RayCastMovement
onready var RayTarget = $RayCastVision
onready var RayItems = $RayCastItems
onready var Target = $Target
onready var PlayerSkills = $PlayerSkills
onready var PlayerItems = $PlayerItems
onready var Tween = $Tween
onready var Sprite = $Sprite
onready var Area2D = $Area2D
onready var healthBar = get_node('HealthBar/HealthBar')
onready var HUD = get_node("/root/World/HUD")

onready var objItem = preload('res://Scenes/Item.tscn')

var isPlayer = true
var isMonster = false
var isItem = false
var hasPlayed = false
var active = false
var state = 'alive' # alive, dead, dying
var dyingCounter = 5 # dies on 5th turn

# Items / Inventory
var items = [null, null, null, null, null, null] # Current items in inventory (strings of item names)
var itemsID = [null, null, null, null, null, null] # Current items in inventory (strings of item names)
var itemsDescription = [null, null, null, null, null, null] # Curernt items' descriptions
var itemsType = [null, null, null, null, null, null] # Current items' type (consumable, weaponMelee, weaponRanged, armor, misc)
var itemsDamage = [null, null, null, null, null, null] # Array of vector2s that contain the minimum & maximum damage of weapons (Vector2.ZERO for non-weapon items)
var itemsState = [null, null, null, null, null, null] # Current items' state (null, unequipped, equipped)
var itemSlots : Array # Array of item slot sprite nodes (sprites inside each inventory slot)
var itemsMode = false # true when pressing inventory button (Tab)
var itemChoose : String # Current highlighted item (item name)
var itemChooseIndex = -1 # Index of current highlighted item

# Items Equipped
var hasEquippedWeapon = false
var hasEquippedArmor = false
var equippedWeaponID = null
var equippedArmorID = null
var equippedWeaponDamage = Vector2(0, 1)
var equippedWeaponType = null
var equippedArmorResistance = 0

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
	
	# Assign item slot sprite nodes
	itemSlots.append(HUD.get_node('Inventory/InvSlot1/Slot'))
	itemSlots.append(HUD.get_node('Inventory/InvSlot2/Slot'))
	itemSlots.append(HUD.get_node('Inventory/InvSlot3/Slot'))
	itemSlots.append(HUD.get_node('Inventory/InvSlot4/Slot'))
	itemSlots.append(HUD.get_node('Inventory/InvSlot5/Slot'))
	itemSlots.append(HUD.get_node('Inventory/InvSlot6/Slot'))
	
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
	
		# Set correct slot sprites from GameManager's skillSlotSprites (if not empty)
		if (skills.empty() == false && skillsArraySize > i):
			var index = GameManager.skillsNames.find(skills[i])
			slot.texture = load(GameManager.skillsSlotSprites[index])
			
		i += 1 # counter increment
		
	# Refresh inventory
	for index in items.size():
		itemSlots[index].texture = null
		
		if (items[index] != null):
			var libraryIndex = GameManager.itemsNames.find(items[index])
			itemSlots[index].texture = load(GameManager.itemsSlotSprites[libraryIndex])

# GET INPUT
func _process(delta):
	# TEST
	if (active == true && targetMode == false && skillMode == false):
		# Level up debug (home key gives 1 level)
		if (Input.is_action_just_pressed("key_home")):
			xpCurrent = xpToLevel
			level_up_check()
		if (Input.is_action_just_pressed("key_c")):
			add_item('Dagger')
		if (Input.is_action_just_pressed("key_g")):
			add_item('Health Potion')
		if (Input.is_action_just_pressed("key_j")):
			print("~~~~~~~")
			print(items)
			print(itemsID)
			print(itemsDescription)
			print(itemsDamage)
			print(itemsMode)
			print(itemsState)
			print(itemsType)
			print(itemSlots)
			print("itemChooseIndex: " + str(itemChooseIndex))
			print("itemChoose: " + itemChoose)
			print("~~~~~~~")
		if (Input.is_action_just_pressed("key_k")):
			print("++++++++++++++++++++++")
			print("hasEquippedArmor: " + str(hasEquippedArmor))
			print("hasEquippedWeapon: " + str(hasEquippedWeapon))
			print("equippedArmorID: " + str(equippedArmorID))
			print("equippedWeaponID: " + str(equippedWeaponID))
			print("equippedWeaponDamage: " + str(equippedWeaponDamage))
			print("equippedWeaponType: " + str(equippedWeaponType))
			print("equippedArmorResistance: " + str(equippedArmorResistance))
			print("++++++++++++++++++++++")
	
	# Check if the player has the ability to take an action
	if (active == true && targetMode == false && skillMode == false && itemsMode == false):
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
		
		# Pick Up Item
		elif (Input.is_action_just_pressed("key_f")):
			# Check current tile for a collision with an item
			RayItems.set_cast_to(Vector2(0, 0))
			RayItems.force_raycast_update()
			
			# Check if inventory is full
			var isFullCounter = 0
			var isFull = false
			for item in items:
				if (item != null):
					isFullCounter += 1
			if (isFullCounter == 6):
				isFull = true
			
			# Add item to inventory, remove item node & end player turn
			if (RayItems.get_collider() != null && isFull == false):
				if (RayItems.get_collider().get_parent().isItem == true):
					add_item(RayItems.get_collider().get_parent().itemName)
					RayItems.get_collider().get_parent().queue_free()
					end_turn()
					
		# Inventory
		elif (Input.is_action_just_pressed("key_tab")):
			itemsMode = true
			
			# Find first non-null item slot & highlight it as soon as the inventory opens
			for item in items:
				if (item != null):
					# Highlight item
					itemChooseIndex = items.find(item)
					itemChoose = items[itemChooseIndex]
					itemSlots[itemChooseIndex].get_parent().scale = Vector2(1.3, 1.3)
					itemSlots[itemChooseIndex].get_parent().modulate = Color(1, 1, 1, 0.8)
					itemSlots[itemChooseIndex].z_index = 1
					
					show_item_details()
					
					break # stop searching 
					
			# Animate the inventory opening
			HUD.get_node('Tween').stop_all()
			HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", Vector2(0, 0), Vector2(0, -192), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
			HUD.get_node('TweenTextTooltip').start()
			HUD.get_node('Inventory/Tween').interpolate_property(HUD.get_node('Inventory'), "position", Vector2(-368, 688), Vector2(0, 688), 0.4, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			HUD.get_node('Inventory/Tween').start()
		# Skills
		elif (Input.is_action_just_pressed("key_shift") && skills.empty() == false && itemsMode == false):
			skillMode = true
			
			skillChooseIndex = 0
			skillChoose = skills[skillChooseIndex]
			
			HUD.get_node('Tween').stop_all()
			HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", Vector2(1, 1), Vector2(1.4, 1.4), 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT )
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
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", Vector2(1, 1), Vector2(1.4, 1.4), 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex - 1], "scale", Vector2(1.4, 1.4), Vector2(1, 1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
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
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", Vector2(1, 1), Vector2(1.4, 1.4), 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex + 1], "scale", Vector2(1.4, 1.4), Vector2(1, 1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		HUD.get_node('Tween').start()
		HUD.get_node('SkillDetails/SkillTitle').bbcode_text = '[center]' + skills[skillChooseIndex] + '[/center]'
		HUD.get_node('SkillDetails/SkillTitleShadow').bbcode_text = '[center][color=#ff212123]' + skills[skillChooseIndex] + '[/color][/center]'
		HUD.get_node('SkillDetails/SkillDescription').bbcode_text = skillsDescription[skillChooseIndex]
		HUD.get_node('SkillDetails/SkillDescriptionShadow').bbcode_text = '[color=#ff212123]' + skillsDescription[skillChooseIndex] + '[/color]'
		HUD.get_node('SkillDetails/SkillCostCooldown').bbcode_text = '[center]- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/center]'
		HUD.get_node('SkillDetails/SkillCostCooldownShadow').bbcode_text = '[center][color=#ff212123]' + '- Cooldown: ' + str(skillsCooldown[skillChooseIndex]) + ', MP: ' + str(skillsManaCost[skillChooseIndex]) + ' -[/color][/center]'
	# Items mode scroll
	# Right
	elif (itemsMode == true && Input.is_action_just_pressed("key_d") && itemChooseIndex < 5 && itemChooseIndex != -1):
		if (items[itemChooseIndex + 1] != null):
			itemChooseIndex += 1
			itemChoose = items[itemChooseIndex]

			itemSlots[itemChooseIndex].z_index = 1
			itemSlots[itemChooseIndex - 1].z_index = 0
			
			itemSlots[itemChooseIndex - 1].get_parent().scale = Vector2(1, 1)
			itemSlots[itemChooseIndex - 1].get_parent().modulate = Color(1, 1, 1, 1)
			itemSlots[itemChooseIndex].get_parent().scale = Vector2(1.3, 1.3)
			itemSlots[itemChooseIndex].get_parent().modulate = Color(1, 1, 1, 0.8)
			
			show_item_details()
#	# Left
	elif (itemsMode == true && Input.is_action_just_pressed("key_a") && itemChooseIndex > 0 && itemChooseIndex != -1):
		if (items[itemChooseIndex - 1] != null):
			itemChooseIndex -= 1
			itemChoose = items[itemChooseIndex]

			itemSlots[itemChooseIndex].z_index = 1
			itemSlots[itemChooseIndex + 1].z_index = 0
			
			itemSlots[itemChooseIndex + 1].get_parent().scale = Vector2(1, 1)
			itemSlots[itemChooseIndex + 1].get_parent().modulate = Color(1, 1, 1, 1)
			itemSlots[itemChooseIndex].get_parent().scale = Vector2(1.3, 1.3)
			itemSlots[itemChooseIndex].get_parent().modulate = Color(1, 1, 1, 0.8)
			
			show_item_details()
	# Cancel Skills
	elif (skillMode == true && (Input.is_action_just_pressed("key_escape") || Input.is_action_just_pressed("key_shift"))):
		skillMode = false
		
		# Leave skills toolbar
		HUD.get_node('Tween').stop_all()
		HUD.get_node('Tween').interpolate_property(skillSlots[skillChooseIndex], "scale", Vector2(1.4, 1.4), Vector2(1, 1), 1.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT )
		HUD.get_node('Tween').start()
		HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", HUD.get_node('SkillsConfirmCancelButtons').position, Vector2(0, 0), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		HUD.get_node('TweenTextTooltip').start()
		HUD.get_node('SkillDetails').visible = false
		
	# Cancel Inventory
	elif (itemsMode == true && (Input.is_action_just_pressed("key_escape") || Input.is_action_just_pressed("key_tab"))):
		close_inventory()
		
	# Use item (Choose)
	elif (itemsMode == true && itemChooseIndex != -1 && Input.is_action_just_pressed("key_space")):
		# Check item type and act accordingly (Consume/Equip/etc.)
		print(items[itemChooseIndex])
		if (itemsType[itemChooseIndex] == 'consumable'):
			PlayerItems.consume_item(items[itemChooseIndex])
			remove_item(itemsID[itemChooseIndex])
			close_inventory()
			end_turn()
		elif (itemsType[itemChooseIndex] == 'weaponMelee' || itemsType[itemChooseIndex] == 'weaponRanged'):
			# Equip weapon (if its ID is different than equippedWeaponID)
			if (equippedWeaponID != itemsID[itemChooseIndex]):
				# Check if a weapon is already equipped and unequip it
				if (hasEquippedWeapon == true):
					var index = itemsID.find(equippedWeaponID)
					itemsState[index] = "unequipped"
				
				# Equip
				hasEquippedWeapon = true
				equippedWeaponID = itemsID[itemChooseIndex]
				equippedWeaponDamage = itemsDamage[itemChooseIndex]
				equippedWeaponType = itemsType[itemChooseIndex]
				itemsState[itemChooseIndex] = 'equipped'
				
				# Show *equip* text
				GameManager.create_status_text(self, "*equip*", '#ffffff')
			# Unequip weapon if the item pressed's ID is the same as equippedWeaponID
			else:
				hasEquippedWeapon = false
				equippedWeaponID = null
				equippedWeaponDamage = Vector2(0, 1)
				equippedWeaponType = null
				itemsState[itemChooseIndex] = 'unequipped'
				
				# Show *unequip* text
				GameManager.create_status_text(self, "*unequip*", '#ffffff')
				
			# Refresh HUD item details
			show_item_details()
		elif (itemsType[itemChooseIndex] == 'armor'):
			print('this item is an armor')
	
	# Drop Item
	elif (itemsMode == true && Input.is_action_just_pressed("key_ctrl") && itemChooseIndex != -1):
		drop_item(itemsID[itemChooseIndex])
		
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
	# Choose Skill
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
	RayMovement.set_cast_to(direction)
	RayMovement.force_raycast_update()
	
	# Check all tilemaps for wall at ray cast direction and move (index of wall is 0 in the tileset!)
	if (RayMovement.get_collider() == null || RayMovement.get_collider().name == "Walls"):
		for tilemap in TileMapAStar.get_children():
			if (tilemap.get_cellv(tilemap.world_to_map(get_global_position() + direction)) != -1):
				# Move
				position += direction
				
				# End Turn
				end_turn()
	# Attack (if monster is at position)
	elif (RayMovement.get_collider().get_parent().isMonster == true):
		animation_attack(direction)
		attack(RayMovement.get_collider().get_parent())

# Attack
func attack(target):
	hasPlayed = true
	active = false
	
	# Check if hit is successful (evasion)
	var hitChance = randi() % 100
	if (hitChance > target.evasionPerc):
		# (Warrior) Cleave check
		PlayerSkills.cleave_check(target)
		
		# (Warrior) Check for execute
		var executeChance = randi() % 100
		if (execute == true && executeChance <= 25 && target.health <= target.healthMax * 0.3):
			PlayerSkills.execute_target(target)
		
		# NORMAL ATTACK !!!
		else:
			# Reduce health
			var weaponDamage = int(equippedWeaponDamage.x) + randi() % int(equippedWeaponDamage.y)
			var damageTotal = strength + weaponDamage - target.damageResistance
			
			print("////////////////")
			print(weaponDamage)
			print("////////////////")
			
			if (target.cursed == true):
				damageTotal = damageTotal * 1.2
			if (invisible == true):
				damageTotal = damageTotal + ceil((dexterity + 2) / 3)
			
			if (damageTotal < 0):
				damageTotal = 0
			target.health -= damageTotal
			
			# Show damage text
			GameManager.create_damage_text(target, damageTotal, '#ffffff')
			
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
		GameManager.create_status_text(target, 'MISS', '#ffffff')
	
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
		
		# XP
		xpCurrent = xpCurrent - xpToLevel
		level += 1
		xpToLevel = ceil(10 + level * 2)
		
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
		
		# Check shadow walk & leap on level-up, too
		check_leap()
		check_shadow_walk()
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
			HUD.get_node('Tween').interpolate_property(slot, "scale", Vector2(1, 1), Vector2(1.5, 1.5), 1.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			HUD.get_node('Tween').start()
			yield(get_tree().create_timer(1.3), "timeout")
			HUD.get_node('Tween').interpolate_property(slot, "scale", Vector2(1.5, 1.5), Vector2(1, 1), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			HUD.get_node('Tween').start()
			
			break # stop searching

# Gives an item to the player
func add_item(itemName):
	for index in itemsID.size():
		if (itemsID[index] == null):
			itemsID[index] = GameManager.create_item_id()
			items[index] = itemName
			
			var libraryIndex = GameManager.itemsNames.find(itemName)
			itemSlots[index].texture = load(GameManager.itemsSlotSprites[libraryIndex])
			itemsDescription[index] = GameManager.itemsDescription[libraryIndex]
			itemsType[index] = GameManager.itemsType[libraryIndex]
			itemsDamage[index] = GameManager.itemsDamage[libraryIndex]
			itemsState[index] = GameManager.itemsState[libraryIndex]
			
			break # stop searching
			

# Drop item from inventory
func drop_item(itemID):
	# Check current tile for a collision with an item
	RayTarget.set_cast_to(Vector2(0, 0))
	RayTarget.force_raycast_update()
	
	# Create item node, remove item from inventory & end player turn
	if (RayTarget.get_collider() == null):
		# Create item node
		var instance = objItem.instance()
		instance.itemName = items[itemChooseIndex]
		instance.set_texture(itemSlots[itemChooseIndex].texture)
		instance.position = position
		RootNode.add_child(instance)
		
		# Empty the inventory slot
		items[itemChooseIndex] = null
		itemsID[itemChooseIndex] = null
		itemsDamage[itemChooseIndex] = null
		itemsDescription[itemChooseIndex] = null
		itemsState[itemChooseIndex] = null
		itemsType[itemChooseIndex] = null
		itemSlots[itemChooseIndex].texture = null
		itemSlots[itemChooseIndex].get_parent().scale = Vector2(1, 1)
		
		# Shift items in inventory
		for index in range(itemChooseIndex + 1, items.size()):
			if (items[index] != null):
				# Move item in the empty slot & make its current slot null
				items[index - 1] = items[index]
				itemsID[index - 1] = itemsID[index]
				itemsDamage[index - 1] = itemsDamage[index]
				itemsDescription[index - 1] = itemsDescription[index]
				itemsState[index - 1] = itemsState[index]
				itemsType[index - 1] = itemsType[index]
				itemSlots[index - 1].texture = itemSlots[index].texture
				
				items[index] = null
				itemsID[index] = null
				itemsDamage[index] = null
				itemsDescription[index] = null
				itemsState[index] = null
				itemsType[index] = null
				itemSlots[index].texture = null
			else:
				break # stop searching
			
		# Close inventory & end turn
		close_inventory()
		end_turn()
	
# Remove item from inventory
func remove_item(itemID):
	# Empty the inventory slot
	items[itemChooseIndex] = null
	itemsID[itemChooseIndex] = null
	itemsDamage[itemChooseIndex] = null
	itemsDescription[itemChooseIndex] = null
	itemsState[itemChooseIndex] = null
	itemsType[itemChooseIndex] = null
	itemSlots[itemChooseIndex].texture = null
	itemSlots[itemChooseIndex].get_parent().scale = Vector2(1, 1)
	
	# Shift items in inventory
	for index in range(itemChooseIndex + 1, items.size()):
		if (items[index] != null):
			# Move item in the empty slot & make its current slot null
			items[index - 1] = items[index]
			itemsID[index - 1] = itemsID[index]
			itemsDamage[index - 1] = itemsDamage[index]
			itemsDescription[index - 1] = itemsDescription[index]
			itemsState[index - 1] = itemsState[index]
			itemsType[index - 1] = itemsType[index]
			itemSlots[index - 1].texture = itemSlots[index].texture
			
			items[index] = null
			itemsID[index] = null
			itemsDamage[index] = null
			itemsDescription[index] = null
			itemsState[index] = null
			itemsType[index] = null
			itemSlots[index].texture = null
		else:
			break # stop searching
	
# Close inventory
func close_inventory():
	itemsMode = false
	itemChoose = ""
	
	# Reset current slot appearance & index
	HUD.get_node('Inventory/Tween').stop_all()
	itemSlots[itemChooseIndex].get_parent().scale = Vector2(1, 1)
	itemSlots[itemChooseIndex].get_parent().modulate = Color(1, 1, 1, 1)
	itemSlots[itemChooseIndex].z_index = 0
	
	# Reset itemChooseIndex
	itemChooseIndex = -1
	
	# Leave inventory
	HUD.get_node('Tween').stop_all()
	HUD.get_node('TweenTextTooltip').interpolate_property(HUD.get_node('SkillsConfirmCancelButtons'), "position", HUD.get_node('SkillsConfirmCancelButtons').position, Vector2(0, 0), 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	HUD.get_node('TweenTextTooltip').start()
	HUD.get_node('Inventory/Tween').interpolate_property(HUD.get_node('Inventory'), "position", HUD.get_node('Inventory').position, Vector2(-368, 688), 0.4, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	HUD.get_node('Inventory/Tween').start()
	HUD.get_node('ItemDetails').visible = false

func show_item_details():
	# Show item details text
	HUD.get_node('ItemDetails').visible = true
	HUD.get_node('ItemDetails/ItemTitle').bbcode_text = items[itemChooseIndex]
	HUD.get_node('ItemDetails/ItemTitleShadow').bbcode_text = '[color=#ff212123]' + items[itemChooseIndex] + '[/color]'
	HUD.get_node('ItemDetails/ItemDescription').bbcode_text = itemsDescription[itemChooseIndex]
	HUD.get_node('ItemDetails/ItemDescriptionShadow').bbcode_text = '[color=#ff212123]' + itemsDescription[itemChooseIndex] + '[/color]'
	
	if (itemsType[itemChooseIndex] == 'weaponMelee'):
		HUD.get_node('ItemDetails/ItemInfo').bbcode_text = 'Melee Weapon, Damage: ' + str(itemsDamage[itemChooseIndex].x) + ' - ' + str(itemsDamage[itemChooseIndex].y) + ', ' + itemsState[itemChooseIndex]
		HUD.get_node('ItemDetails/ItemInfoShadow').bbcode_text = '[color=#ff212123]' + 'Melee Weapon, Damage: ' + str(itemsDamage[itemChooseIndex].x) + ' - ' + str(itemsDamage[itemChooseIndex].y) + ', ' + itemsState[itemChooseIndex] + '[/color]'
	elif (itemsType[itemChooseIndex] == 'weaponRanged'):
		HUD.get_node('ItemDetails/ItemInfo').bbcode_text = 'Ranged Weapon, Damage: ' + str(itemsDamage[itemChooseIndex].x) + ' - ' + str(itemsDamage[itemChooseIndex].y) + ', ' + itemsState[itemChooseIndex]
		HUD.get_node('ItemDetails/ItemInfoShadow').bbcode_text = '[color=#ff212123]' + 'Ranged Weapon, Damage: ' + str(itemsDamage[itemChooseIndex].x) + ' - ' + str(itemsDamage[itemChooseIndex].y) + ', ' + itemsState[itemChooseIndex] + '[/color]'
	elif (itemsType[itemChooseIndex] == 'consumable'):
		HUD.get_node('ItemDetails/ItemInfo').bbcode_text = 'Consumable'
		HUD.get_node('ItemDetails/ItemInfoShadow').bbcode_text = '[color=#ff212123]Consumable[/color]'

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
	check_leap()
		
	# Check shadow walk duration (Rogue only) (Uses range for duration)
	check_shadow_walk()

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

# Check shadow walk function
func check_shadow_walk():
	var index = skills.find('Shadow Walk')
	if (index != -1):
		skillsRange[index] = ceil(dexterity / 3.0)

# Check leap function
func check_leap():
	var index = skills.find('Leap')
	if (index != -1):
		skillsRange[index] = clamp(ceil(dexterity / 8.0), 0, 10)
##########################################################################################
# ANIMATIONS (Duration must be lower than 0.2 always)
func animation_attack(direction):
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position + direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
	yield(get_tree().create_timer(0.07), "timeout")
	Tween.interpolate_property(Sprite, "position", Sprite.position, Sprite.position - direction, 0.06, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()
