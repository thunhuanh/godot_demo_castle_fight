extends Node2D

const MAXIMUM_WORK_DISTANCE := 32

var dragging = false
var selectedBuilder : Builder = null
var dragStart = Vector2.ZERO
var selectedRect = RectangleShape2D.new()
var canPlace = false
var invalid_tiles = [] # list of tile that bu	ilder cannot build on
var buildDestination = Vector2.ZERO
var buildDestTile
var isBuilding = false

remote var slaveDest : Vector2 = Vector2.ZERO

signal setBuilder(builder)
signal updatePathfinding(pathfinding)

export var building = preload("res://Scenes/building.tscn")
export var soldier = preload("res://Scenes/soldier.tscn")

var builder : Builder = null
onready var uiControl = $UI/Control
onready var selectRectDraw : Node2D = $selectionRect
onready var pointer : Node2D = $pointer
onready var buildingPlacement : TileMap = $building_placement
onready var buildings  : YSort = $instanceSort/buildings
onready var mainHouse : StaticBody2D = $instanceSort/mainHouse
onready var enemyHouse : StaticBody2D = $instanceSort/enemyHouse
onready var env : TileMap = $enviroment
onready var pathfinding : Pathfinding = $pathfinding

func _ready():
	connect("setBuilder", self, "setBuilder")
	# connect signal for multiplayer
	
	pathfinding.genMap(env)
	var mainHouseTile = env.world_to_map(mainHouse.position)
	var enemyHouseTile = env.world_to_map(enemyHouse.position)
	# diable point in mainHouseTile and enemyHoustTile
#	pathfinding.disablePoint(mainHouseTile)
#	pathfinding.disablePoint(mainHouseTile + Vector2(-1, 1))
#	pathfinding.disablePoint(mainHouseTile + Vector2(0, 1))
#	pathfinding.disablePoint(mainHouseTile + Vector2(1, 1))
#	pathfinding.disablePoint(enemyHouseTile)
#	pathfinding.disablePoint(enemyHouseTile + Vector2(-1, 0))
#	pathfinding.disablePoint(enemyHouseTile + Vector2(1, 0))
	
	# add mainHouse and enemyHoust to invalid_tiles
	invalid_tiles = invalid_tiles + [mainHouseTile, mainHouseTile + Vector2(-1, 1),
	 mainHouseTile + Vector2(0, 1), enemyHouseTile, enemyHouseTile + Vector2(-1, 0),
	 enemyHouseTile + Vector2(1, 0)]

remote func setBuilder(_builder: Builder) :
	builder = _builder
	builder.setPathfinding(pathfinding)

func _process(_delta):
	# checked if player reach building place
	if buildDestTile != null and reachedBuildingPlace() and isBuilding:
	
		var tile = buildingPlacement.world_to_map(buildDestination)

		var newBuilding = building.instance()
		newBuilding.position = tile * Vector2(32, 32)
		
		if not tile in invalid_tiles:
			buildings.add_child(newBuilding)
			# remove from pathfinding
			invalid_tiles.append(tile)
			pathfinding.disablePoint(tile)
			# emit signal to soldier to update pathfinding graph
			emit_signal("updatePathfinding", pathfinding)
			
			builder.setPathfinding(pathfinding)
			builder.stop()

		isBuilding = false
		resetBuildPlacement()
			

func reachedBuildingPlace():
	var destinationPos = buildingPlacement.map_to_world(buildDestTile, false)
	if builder.position.distance_to(destinationPos + Vector2(16, 16)) <= 32:
		return true

func _unhandled_input(event):
	var mousePos = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			if !canPlace:
				deselectUnit()
			if canPlace:
				placeBuilding()
			return
		if dragging:
			selectUnit()
			return
		
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		if event.is_pressed():
			pointer.update_status(mousePos, true)
			return
			
		pointer.update_status(mousePos, false)
		if selectedBuilder != null:
			#if mouse is release
			selectedBuilder.move_to(mousePos)
			
		return
	
	if event.is_action_pressed("ui_cancel"):
		resetBuildPlacement()
	
	if event is InputEventMouseMotion:
		if canPlace:
			buildingPlacement.clear()
			var tile = buildingPlacement.world_to_map(mousePos)
			if not tile in invalid_tiles:
				buildingPlacement.set_cell(tile.x, tile.y, 0)
			else:
				buildingPlacement.set_cell(tile.x, tile.y, 1)
		if dragging:
			selectRectDraw.update_status(dragStart, mousePos, dragging)

func deselectUnit():
	if selectedBuilder != null:
		selectedBuilder.deselect()
		uiControl.visible = false
	selectedBuilder = null
	dragging = true
	dragStart = get_global_mouse_position()

func selectUnit():
	
	#clear dragging rectangle
	var dragEnd = get_global_mouse_position()
	dragging = false
	selectRectDraw.update_status(dragStart, dragEnd, dragging)
	
	
	#extends rect
	selectedRect.extents = (dragEnd - dragStart) / 2
	
	#get world space
	var space = get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	
	#set query shape is rectangle
	query.set_shape(selectedRect)
	query.transform = Transform2D(0, (dragEnd + dragStart) / 2)
	
	var intersectShapes = space.intersect_shape(query)
	#select unit inside rectangle
	for shape in intersectShapes:
		if builder && shape.collider.name == builder.name:
			selectedBuilder = shape.collider
			selectedBuilder.select()
			
			#hide/unhide ui control
			uiControl.visible = true

func placeBuilding():
	var global_mouse_position := get_global_mouse_position()
	buildDestination = global_mouse_position
	var is_close_to_player := (
		global_mouse_position.distance_to(builder.global_position)
		<= MAXIMUM_WORK_DISTANCE
	)

	#check
	var builderPos = builder.position
	if builderPos.distance_to(buildDestination) < 32:
		var directionToMove = builderPos.direction_to(buildDestination)
		builder.move_to(-directionToMove)

	#reset place ment
	resetBuildPlacement()
	
	#prepate tile for placing building
	var tile = buildingPlacement.world_to_map(global_mouse_position)
	buildDestTile = tile
	
	var newBuilding = building.instance()
	newBuilding.position = tile * Vector2(32, 32)
	
	#if close to player and tile is valid then place building
	if not tile in invalid_tiles && is_close_to_player:
		buildings.add_child(newBuilding)
		# remove from pathfinding
		invalid_tiles.append(tile)
		pathfinding.disablePoint(tile)
		
		# emit signal to update pathfinding grapth of soldier
		emit_signal("updatePathfinding", pathfinding)
		
		builder.setPathfinding(pathfinding)
		builder.stop()

	#else move to build dest
	elif not tile in invalid_tiles:
		isBuilding = true
		builder.move_to(global_mouse_position)
	
func resetBuildPlacement():
	buildingPlacement.clear()
	canPlace = false

func _on_Button_pressed():
	buildingPlacement.clear()
	canPlace = !canPlace
