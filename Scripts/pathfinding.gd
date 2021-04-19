extends Node
class_name Pathfinding

var aStar2D : AStar2D
var tilemap : TileMap
var usedRect : Rect2
var halfCellSize : Vector2

func _ready() -> void:
	aStar2D = AStar2D.new()

func genMap(_tilemap: TileMap) -> void:
	self.tilemap = _tilemap
	aStar2D.clear()
	
	var tiles = tilemap.get_used_cells()
	halfCellSize = tilemap.cell_size / 2
	usedRect = tilemap.get_used_rect()
	
	addPoint(tiles)
	connectPoint(tiles)
	
# add point
func addPoint(tiles: Array) -> void:
	for cell in tiles:
		aStar2D.add_point(id(cell), cell, 1.0)

# connect point
func connectPoint(tiles: Array) -> void:
	for cell in tiles:
		# 8 neighbor
		#	1 2 3
		#	4 0 5
		# 	6 7 8
		for x in range(3):
			for y in range(3):
				var nextCell = cell + Vector2(float(x - 1), float(y - 1))
				
				if cell == nextCell or not aStar2D.has_point(id(nextCell)):
					continue
				
				aStar2D.connect_points(id(cell), id(nextCell), true)

func disablePoint(point) -> void:
	if not aStar2D.is_point_disabled(id(point)):
		aStar2D.set_point_disabled(id(point), true)

func enablePoint(point) -> void:
	if aStar2D.is_point_disabled(id(point)):
		aStar2D.set_point_disabled(id(point), false)
	
	
# calculate cell index
func id(point) -> int:
	# subtract offset from position
	point -= usedRect.position
	return point.y * usedRect.size.x + point.x

# return path calculate by aStar
func getPath(start, end) -> Array:
	var startTile = tilemap.world_to_map(start)
	var endTile = tilemap.world_to_map(end)
	if not aStar2D.has_point(id(startTile)) or not aStar2D.has_point(id(endTile)):
		return []
	var path = aStar2D.get_point_path(id(startTile), id(endTile))
	path.remove(0)
	
	var pathWorld = []
	for point in path:
		var pointInWorld = tilemap.map_to_world(point) + halfCellSize
		pathWorld.append(pointInWorld)
	return pathWorld

