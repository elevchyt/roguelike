extends Node2D

onready var TileMapAStar = get_node("/root/World/TileMapAStar")
onready var GameManager = get_node("/root/World/GameManager")
onready var Ray = $Area2D/RayCast2D
onready var Tween = $Tween

export var visionRange = 999 # the number of steps where this unit will become aggressive towards the player
var isPlayer = false
var hasPlayed = false

# Moves next to target
func move(path):
	var stepsCounter = 1 # normally happens when this unit's turn happens again!
	for step in path:
		if (stepsCounter > 0):
			stepsCounter -= 1
			position = step

# Activate function (when this unit enters it's turn)
func activate():
	# Find closest player & its path
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
			if (Ray.get_collider().get_parent() == targetPlayer): # !!!!!!!!!!!!
				targetInAttackRange = true
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
		
	# End Turn
	hasPlayed = true
