extends Node2D

onready var CameraNode = get_node("/root/World/Camera2D")
onready var HUD = get_node("/root/World/HUD")
onready var turnOrder: Array
onready var players : Array
onready var playerCurrentIndex : int

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
	for creature in get_node("/root/World/Creatures").get_children():
		if (creature.isPlayer == false):
			turnOrder.append(creature)
		elif (creature.isPlayer && creature.state != 'dead'):
			players.append(creature)
	turnOrder = players + turnOrder
	
	print('- TURN ORDER -')
	for i in turnOrder:
		print(i.name)
	print('--------------')
	
# Activate the next available player, otherwise run the AI turns & reset index
func next_player_turn():
	# Check if all players are dead
	if (players.empty()):
		print('** ALL PLAYERS ARE DEAD! **')
		print('** GAME OVER **')
	# Activate players in order
	elif (playerCurrentIndex != players.size() && players[playerCurrentIndex].state != 'dead'):
		players[playerCurrentIndex].activate()
		HUD.currentPlayer = players[playerCurrentIndex]
		CameraNode.position = players[playerCurrentIndex].position
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
	
	# Start players' turns 
	yield(get_tree().create_timer(0.2), "timeout")
	next_player_turn()

##################################################################################################
# SKILLS LIBRARY (is referred after skill is granted to a player)
var skillsNames = ['Flare', 'Thunderclap', 'Arcane Shield', 'Curse', 'Healing Prayer']
var skillsDescription = ['Shoots a flare that inflicts INT / 2 + STR / 4 damage to a target.', 
'Inflicts INT + (STR / 2) damage to enemies around you. (Cannot be evaded)', 
'(PASSIVE) All damage taken is reduced by 20%, as long as your Mana is over 50%.', 
'Casts a curse on a target for 3 turns. Cursed targets take 20% more damage from all sources & have their Evasion reduced to 0%. (Cannot be evaded)',
'Heals a friendly target for INT * 0.8.']
var skillsSlotSprites = ['res://Sprites/skill_flare.png', 
'res://Sprites/skill_thunderclap.png', 
'res://Sprites/skill_arcane_shield.png', 
'res://Sprites/skill_curse.png',
'res://Sprites/skill_healing_prayer.png'] # replace this
var skillsManaCost = [4, 6, 0, 12, 5]
var skillsCooldown = [0, 5, 0, 12, 5]
var skillsRange = [5, 1, 0, 4, 3]
# skillsType: 'passive, 'active'
var skillsType = ['active', 'active', 'passive', 'active', 'active']
# skillsTargetType: 'self', 'target+enemy', 'around+enemy', 'target+friendly', 'passive'
var skillsTargetType = ['target+enemy', 'around+enemy', 'passive', 'target+enemy', 'target+friendly']
