extends Node2D

onready var CameraNode = get_node("/root/World/Camera2D")
onready var HUD = get_node("/root/World/HUD")
onready var Tween = $Tween

onready var turnOrder: Array
onready var players : Array
onready var playerCurrentIndex : int
onready var gameOver = false
onready var itemIDGenerator = 0 # increments & is assigned to an item in inventory when picked up

# General objects for instancing
onready var objDamageText = preload('res://Scenes/TextDamage.tscn')
onready var objStatusTextIndependent = preload('res://Scenes/TextStatusIndependent.tscn')
onready var objDamageTextIndependent = preload('res://Scenes/TextDamageIndependent.tscn')

# DEBUG BUTTONS
func _process(delta):
	if (Input.is_action_just_pressed("key_r")):
		get_tree().reload_current_scene()

func _ready():
	# RE-ROLL RNG AT START
	randomize()
	
	# Launch game!
	calc_turn_order()
	next_player_turn() # activate first player's turn

# Calculate order of creature turns (fifo)
# (players always play first)
# must be called at the beginning of every creature's turn to make sure it doesn't look for destroyed creatures
func calc_turn_order():
	turnOrder.clear()
	players.clear()
	var CreaturesNode = get_node("/root/World/Creatures").get_children()
	for creature in CreaturesNode:
		if (creature.isPlayer == false):
			turnOrder.append(creature)
		elif (creature.isPlayer):
			if (creature.state != 'dead'):
				players.append(creature)
		
	
	print('THIS IS THE SIZE: ' + str(players.size()))
	turnOrder = players + turnOrder
	
	print('- TURN ORDER -')
	for i in turnOrder:
		print(i.name)
	print('--------------')
	
# Activate the next available player, otherwise run the AI turns & reset index
func next_player_turn():
	print('-------------------')
	print(playerCurrentIndex)
	print(players.size())
	print('-------------------')
	# Check if all players are dead
	if (players.empty()):
		print('** ALL PLAYERS ARE DEAD! **')
		print('** GAME OVER **')
		gameOver = true
		HUD.hide()
	# Activate players in order
	elif (playerCurrentIndex < players.size()):
		if (players[playerCurrentIndex].state == 'alive'):
			players[playerCurrentIndex].activate()
			HUD.currentPlayer = players[playerCurrentIndex]
			CameraNode.position = players[playerCurrentIndex].position
		# Skip dying players' turn
		else:
			players[playerCurrentIndex].end_turn()
			
		playerCurrentIndex += 1
	else:
		playerCurrentIndex = 0
		launch_ai_turns()
		
# Launch AI creatures' turns after all players have finished their turns
func launch_ai_turns():
	# Creatures' turn (activate)
	for creature in turnOrder:
		if (creature.isPlayer == false):
			creature.activate()
	
	# Check for dying players at the end of every turn
	print(players)
	for player in players:
		if (player.state == 'dying'):
			print(player.dyingCounter)
			player.dyingCounter -= 1
			
			# Check for death of dying player
			if (player.dyingCounter <= 0):
				# Reset HUD 
				HUD.currentPlayer = null
				
				# Set player state & current player index & remove node
				playerCurrentIndex = 0
				player.state = 'dead'
				player.queue_free()
				players.remove(playerCurrentIndex)
				
	# Start players' turns 
	if (gameOver == false):
		calc_turn_order()
		next_player_turn()

# Item ID Assign
func create_item_id():
	itemIDGenerator += 1
	return itemIDGenerator

# DAMAGE/STATUS TEXT FUNCTIONS
# Create independent damage text
func create_damage_text(target, damage, colorHex):
	var damageText = objDamageTextIndependent.instance()
	damageText.position = to_local(target.position)
	add_child(damageText)
	
	z_index = 3
	damageText.get_node('TextDamage').bbcode_text = '[center][color=' + colorHex + ']' + '-' + str(damage) + '[/color][/center]'
	damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damage) + '[/color][/center]'
	Tween.interpolate_property(damageText, "position", to_local(target.position), to_local(target.position) + Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()

# Create independent damage text with X & Y Offset
func create_damage_text_offset(target, damage, colorHex):
	var randXOffset = ceil(rand_range(-48, 48))
	var randYOffset = ceil(rand_range(-102, -148))
	randomize()
	var damageText = objDamageTextIndependent.instance()
	damageText.position = to_local(target.position)
	add_child(damageText)
	
	z_index = 3
	damageText.get_node('TextDamage').bbcode_text = '[center][color=' + colorHex + ']' + '-' + str(damage) + '[/color][/center]'
	damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damage) + '[/color][/center]'
	Tween.interpolate_property(damageText, "position", to_local(target.position) + Vector2(randXOffset, 0), to_local(target.position) + Vector2(randXOffset, randYOffset), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()

# Create independent healing text
func create_healing_text(target, healing):
	var damageText = objDamageTextIndependent.instance()
	damageText.position = to_local(target.position)
	add_child(damageText)
	
	z_index = 3
	damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffa2dcc7]' + '+' + str(healing) + '[/color][/center]'
	damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '+' + str(healing) + '[/color][/center]'
	Tween.interpolate_property(damageText, "position", to_local(target.position), to_local(target.position) + Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()

# Create independent mana recover text
func create_mana_recover_text(target, manaRestore):
	var damageText = objDamageTextIndependent.instance()
	damageText.position = to_local(target.position)
	add_child(damageText)
	
	z_index = 3
	damageText.get_node('TextDamage').bbcode_text = '[center][color=#ff68c2d3]' + '+' + str(manaRestore) + '[/color][/center]'
	damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '+' + str(manaRestore) + '[/color][/center]'
	Tween.interpolate_property(damageText, "position", to_local(target.position), to_local(target.position) + Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
	Tween.start()

# Create independent status text
func create_status_text(target, text, colorHex):
	var statusText = objDamageTextIndependent.instance()
	statusText.position = to_local(target.position)
	add_child(statusText)
	
	z_index = 3
	statusText.get_node('TextDamage').bbcode_text = '[center][color=' + colorHex + ']' + str(text) + '[/color][/center]'
	statusText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + str(text) + '[/color][/center]'
	Tween.interpolate_property(statusText, "position", to_local(target.position), to_local(target.position) + Vector2(0, -224), 2.3, Tween.EASE_IN_OUT, Tween.EASE_OUT)
	Tween.start()

##################################################################################################
# SKILLS LIBRARY (is referred after skill is granted to a player)
var skillsNames = ['Flare', 'Thunderclap', 'Arcane Shield', 'Curse', 
'Healing Prayer', 'Purify', 'Divine Shield', 'Ressurect',
'Cleave', 'Retaliation', 'Execute', 'Berserk',
'Poison Dart', 'Ensnare', 'Leap', 'Shadow Walk']
var skillsDescription = ['Shoots a flare that inflicts INT / 2 + STR / 4 damage to a target.', 
'Inflicts INT + (STR / 2) damage to enemies around you. (Cannot be evaded)', 
'(PASSIVE) All damage taken is reduced by 20%, as long as your Mana is over 50%.', 
'Casts a curse on a target for 3 turns. Cursed targets take 20% more damage from all sources & have their Evasion reduced to 0%. (Cannot be evaded)',
'Heals a friendly target for INT * 0.8.',
'Removes all debuffs from a friendly target.',
'Renders a friendly target invulnerable for the next 2 turns.',
'Brings a friendly target back to life with 20% of their health & mana restored.',
'(PASSIVE) Melee attacks have a 50% chance to cleave; inflicting STR / 2 damage to enemies adjacent to the target.',
'For the next 2 turns, every melee attack directed at you will also deal STR / 3 + DEX / 2 damage to the attacker.',
'(PASSIVE) Your melee attacks have a 25% chance to execute targets whose health is under 30%.',
'For the next 3 turns, your melee attacks deal x1.5 damage & have 100% chance to cleave, but attacking reduces your health by 5% of your max health.',
'Shoots a poisonous dart that inflicts STR damage with a 50% chance to poison its target for 3 turns. Poisoned targets take INT / 2 damage every time they finish their turn.',
'Tosses a net onto a target, rendering them unable to move and reducing their Evasion to 0% for the next 2 turns.',
'Leaps up to DEX / 4 steps towards any direction. (max. 10 steps)',
'Become invisible for the next DEX / 3 turns. Any non-movement action cancels the effect. Attacks while invisible deal a bonus (DEX + 2) / 3 damage.']
var skillsSlotSprites = [
'res://Sprites/skill_flare.png', 
'res://Sprites/skill_thunderclap.png', 
'res://Sprites/skill_arcane_shield.png', 
'res://Sprites/skill_curse.png',
'res://Sprites/skill_healing_prayer.png',
'res://Sprites/skill_purify.png',
'res://Sprites/skill_divine_shield.png',
'res://Sprites/skill_ressurect.png',
'res://Sprites/skill_cleave.png',
'res://Sprites/skill_retaliation.png',
'res://Sprites/skill_execute.png',
'res://Sprites/skill_berserk.png',
'res://Sprites/skill_poison_dart.png',
'res://Sprites/skill_ensnare.png',
'res://Sprites/skill_leap.png',
'res://Sprites/skill_shadow_walk.png']
var skillsManaCost = [4, 6, 0, 12, 
5, 5, 12, 30,
0, 2, 0, 4,
3, 5, 10, 18]
var skillsCooldown = [2, 5, 0, 12, 
5, 3, 10, 20,
0, 6, 0, 20,
5, 7, 4, 20]
var skillsRange = [5, 1, 0, 4, 
3, 3, 3, 3,
0, 0, 0, 0,
4, 3, 1, 1]
# skillsType: 'passive, 'active'
var skillsType = ['active', 'active', 'passive', 'active', 
'active', 'active', 'active', 'active',
'passive', 'active', 'passive', 'active',
'active', 'active', 'active', 'active']
# skillsTargetType: 'self', 'target+enemy', 'around+enemy', 'target+friendly', 'passive', 'target+floor'
var skillsTargetType = ['target+enemy', 'around+enemy', 'passive', 'target+enemy', 
'target+friendly', 'target+friendly', 'target+friendly', 'target+friendly',
'passive', 'self', 'passive', 'self',
'target+enemy', 'target+enemy', 'target+floor', 'self']

##################################################################################################
# ITEMS LIBRARY (is referred after item is granted to a player)
var itemsNames = ['Dagger',
'Club',
'Axe',
'Shortsword',
'Longsword',
'Broadsword',
'Health Potion',
'Mana Potion',
'Leather Armor',
'Iron Armor',
'Chainmail Armor']
var itemsDescription = ["A sharp dagger made of steel.",
"Wooden club for good ol' skull bashing.",
"A small wood cutting axe.",
"A light sword with a steel blade. Great for versatile fighters.",
"A steel longsword with a sharp blade and a steady hilt.",
"A huge sword with a deadly blow.",
"Restores 10% of the user's health.",
"Restores 10% of the user's mana.",
"Armor made of studded leather that focuses on agility over protection.",
"Armor made of iron that provides good all-around protection.",
"Armor made of steel rings that provides astounding defense.",]
var itemsSlotSprites = ['res://Sprites/item_dagger.png',
'res://Sprites/item_club.png',
'res://Sprites/item_axe.png',
'res://Sprites/item_shortsword.png',
'res://Sprites/item_longsword.png',
'res://Sprites/item_broadsword.png',
'res://Sprites/item_potion_health.png',
'res://Sprites/item_potion_mana.png',
'res://Sprites/armor_leather.png',
'res://Sprites/armor_iron.png',
'res://Sprites/armor_chainmail.png',]
var itemsType = ['weaponMelee', 
'weaponMelee',
'weaponMelee',
'weaponMelee',
'weaponMelee',
'weaponMelee',
'consumable',
'consumable',
'armor',
'armor',
'armor']
var itemsState = ['unequipped', 
'unequipped',
'unequipped',
'unequipped',
'unequipped',
'unequipped',
'-',
'-',
'unequipped',
'unequipped',
'unequipped']
var itemsDamage = [0.2, 
0.1,
0.15,
0.25,
0.3,
0.35,
null,
null,
null,
null,
null]
# itemsResistance: in decimals!
var itemsResistance = [null, 
null,
null,
null,
null,
null,
null,
null,
0.1,
0.15,
0.25]
var itemsEvasionReduce = [0, 
0,
0,
10,
15,
25,
null,
null,
0,
20,
40]
