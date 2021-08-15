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
	next_player_turn()
##################################################################################################
# SKILLS LIBRARY (is referred after skill is granted to a player)
var skillsNames = ['Flare', 'Thunderclap', 'Arcane Shield', 'Curse']
var skillsDescription = ['Flare', 'Thunderclap', 'Arcane Shield', 'Curse']
var skillsSlotSprites = ['res://Sprites/skill_flare.png', 'res://Sprites/skill_thunderclap.png', 'res://Sprites/skill_arcane_shield.png', 'res://Sprites/skill_curse.png']
var skillsCooldowns
var skillsFormula
var skillType
var skillsTargetType
