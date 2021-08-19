# NOTES
# The tilemap that this script is on should be empty (have no tiles/tilesets)!
# Pathfinding points are created on every tile of every children of this node whose index is not 0!
# Tiles with index 0 are always treated as walls (if you want more walls then change line 29 on this
# script and line 39 on Player.gd to include another index as a wall)

extends TileMap

onready var astar = AStar2D.new()
onready var rootNode = get_node("/root/World")

var floorCells : PoolVector2Array

func _ready():
	generate_grid()

# Generate points & connect them (called on every creature's turn)
func generate_grid():
	# Get all floor cell positions (for this and for its children)
	for tilemap in get_children():
		var allCells = tilemap.get_used_cells()
		for cell in allCells:
			if (tilemap.get_cellv(cell) != 0):
				floorCells.append(cell)
	
	# Create points
	astar.clear()
	
	for cell in floorCells:
		astar.add_point(id_generate(cell), cell, 1)
	
	# Connect all points with their neighbour points (up, down, left, right)
	for cell in floorCells:
		var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
		for dir in directions:
			astar.connect_points(id_generate(cell), id_generate(cell + dir), false)
	
# Find path to target creature
func find_path(start, end):
	# Disable points that are currently occupied by creatures (excluding start & end creature points!)
	var occupiedCells : PoolVector2Array
	for creature in get_node("/root/World/Creatures").get_children():
		if(creature.get_global_position() != start && creature.get_global_position() != end):
			occupiedCells.append(world_to_map(creature.get_global_position()))
			
	for cell in floorCells:
		astar.set_point_disabled(id_generate(cell), false)
	for cell in occupiedCells:
		astar.set_point_disabled(id_generate(cell), true)
	
	# Create path to target
	var path = astar.get_point_path(id_generate(world_to_map(start)), id_generate(world_to_map(end)))
	var pathCoords : PoolVector2Array
	for step in path:
		pathCoords.append(map_to_world(step))
	
	return pathCoords

# Find path for targeted skills
func find_path_skill(start, end):
	for cell in floorCells:
		astar.set_point_disabled(id_generate(cell), false)
	
	# Create path to target
	var path = astar.get_point_path(id_generate(world_to_map(start)), id_generate(world_to_map(end)))
	var pathCoords : PoolVector2Array
	for step in path:
		pathCoords.append(map_to_world(step))
	
	return pathCoords

# Unique ID Generation based on Vector2 (Cantor Pairing Function)
func id_generate(point):
	var a = point.x
	var b = point.y
	return (a + b) * (a + b + 1) / 2 + b
