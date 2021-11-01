extends Node2D

onready var Root = get_node("/root/World/")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var Player = get_parent()

func consume_item(itemName):
	match itemName:
		"Health Potion":
			var amount = ceil(Player.healthMax * 0.1)
			Player.health = clamp(Player.health + amount, Player.health, Player.healthMax)
			
			# Show health added number text
			GameManager.create_healing_text(Player, str(amount) + " HP")
		"Mana Potion":
			var amount = ceil(Player.manaMax * 0.1)
			Player.mana = clamp(Player.mana + amount, Player.mana, Player.manaMax)
			
			# Show health added number text
			GameManager.create_mana_recover_text(Player, str(amount) + " MP")

func equip_weapon(itemID):
	# Equip weapon (if its ID is different than equippedWeaponID)
	if (Player.equippedWeaponID != itemID):
		# Check if a weapon is already equipped and unequip it
		if (Player.hasEquippedWeapon == true):
			var index = Player.itemsID.find(Player.equippedWeaponID)
			Player.itemsState[index] = "unequipped"
		
		# Equip
		Player.hasEquippedWeapon = true
		Player.equippedWeaponID = Player.itemsID[Player.itemChooseIndex]
		Player.equippedWeaponDamage = Player.itemsDamage[Player.itemChooseIndex]
		Player.equippedWeaponType = Player.itemsType[Player.itemChooseIndex]
		Player.itemsState[Player.itemChooseIndex] = 'equipped'
		
		# Show *equip* text
		GameManager.create_status_text(Player, "*equip*", '#ffffff')
	# Unequip weapon if the item pressed's ID is the same as equippedWeaponID
	else:
		Player.hasEquippedWeapon = false
		Player.equippedWeaponID = null
		Player.equippedWeaponDamage = Vector2(0, 1)
		Player.equippedWeaponType = null
		Player.itemsState[Player.itemChooseIndex] = 'unequipped'
		
		# Show *unequip* text
		GameManager.create_status_text(Player, "*unequip*", '#ffffff')

func equip_armor(itemID):
	# Equip armor (if its ID is different than equippedArmorID)
	if (Player.equippedArmorID != itemID):
		# Check if an armor is already equipped, unequip it and remove its evasion reduction
		if (Player.hasEquippedArmor == true):
			var index = Player.itemsID.find(Player.equippedArmorID)
			Player.itemsState[index] = 'unequipped'
			Player.evasionPerc = Player.evasionPercPure
		
		# Equip
		Player.hasEquippedArmor = true
		Player.equippedArmorID = Player.itemsID[Player.itemChooseIndex]
		Player.equippedArmorResistance = Player.itemsResistance[Player.itemChooseIndex]
		Player.equippedArmorEvasionReduction = Player.itemsEvasionReduce[Player.itemChooseIndex]
		Player.itemsState[Player.itemChooseIndex] = 'equipped'
		
		# Apply Evasion reduction
		Player.evasionPerc = clamp(Player.evasionPerc - Player.equippedArmorEvasionReduction, 0, 50)
		
		# Show *equip* text
		GameManager.create_status_text(Player, "*equip*", '#ffffff')
	# Unequip armor if the item pressed's ID is the same as equippedArmorID
	else:
		# Reset equipped armor settings
		Player.hasEquippedArmor = false
		Player.equippedArmorID = null
		Player.equippedArmorResistance = 0
		Player.equippedArmorEvasionReduction = 0
		Player.itemsState[Player.itemChooseIndex] = 'unequipped'
		
		# Remove Evasion reduction
		Player.evasionPerc = Player.evasionPercPure
		
		# Show *unequip* text
		GameManager.create_status_text(Player, "*unequip*", '#ffffff')
