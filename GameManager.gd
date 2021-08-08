extends Node2D

onready var Player = get_node("/root/World/Creatures/Player")
onready var turnOrder: Array

func _ready():
	# Begin game
	calc_turn_order()
	Player.activate()

# Calculate order of creature turns (fifo)
# (player always plays first)
# must be called at the beginning of every creature's turn to make sure it doesn't look for destroyed creatures
func calc_turn_order():
	turnOrder.clear()
	for creature in get_node("/root/World/Creatures").get_children():
		if (creature.isPlayer == false):
			turnOrder.append(creature)
	turnOrder.push_front(Player)
	
	print('- TURN ORDER -')
	for i in turnOrder:
		print(i.name)
	print('--------------')

func launch_round():
	# Creatures' turn (activate)
	for creature in turnOrder:
		if (creature != Player):
			creature.activate()
	
	# Activate player's turn (again)
	yield(get_tree().create_timer(0.15), "timeout")
	calc_turn_order()
	Player.activate()
