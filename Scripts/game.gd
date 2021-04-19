extends Node2D

const MAXIMUM_WORK_DISTANCE := 32

var dragging = false
var selectedBuilder = null
var dragStart = Vector2.ZERO
var selectedRect = RectangleShape2D.new()
var canPlace = false
var invalid_tiles = []
var buildDestination = Vector2.ZERO
var buildDestTile
var isBuilding = false

onready var building = preload("res://Scenes/building.tscn")

onready var uiControl = $UI/Control
onready var selectRectDraw = $selectionRect
onready var pointer = $pointer
onready var builder = $instanceSort/builder
onready var buildingPlacement = $building_placement
onready var buildings = $instanceSort/buildings
onready var mainHouse = $instanceSort/mainHouse
onready var enemyHouse = $instanceSort/enemyHouse
onready var env = $enviroment
onready var pathfinding = $pathfinding

func _ready():
	pathfinding.genMap(env)
	var mainHouseTile = env.world_to_map(mainHouse.position)
	var enemyHouseTile = env.world_to_map(enemyHouse.position)
	pathfinding.disablePoint(mainHouseTile)
	pathfinding.disablePoint(mainHouseTile + Vector2(-1, 1))
	pathfinding.disablePoint(mainHouseTile + Vector2(0, 1))
	pathfinding.disablePoint(mainHouseTile + Vector2(1, 1))
	pathfinding.disablePoint(enemyHouseTile)
	pathfinding.disablePoint(enemyHouseTile + Vector2(-1, 1))
	pathfinding.disablePoint(enemyHouseTile + Vector2(0, 1))
	pathfinding.disablePoint(enemyHouseTile + Vector2(1, 1))
	
	builder.setPathfinding(pathfinding)

func _process(delta):
	# checked if player 
	if buildDestTile != null and reacedBuildingPlace(buildDestination) and isBuilding:
	
		var tile = buildingPlacement.world_to_map(buildDestination)

		var newBuilding = building.instance()
		newBuilding.position = tile * Vector2(32, 32)
		
		if not tile in invalid_tiles:
			buildings.add_child(newBuilding)
			# remove from pathfinding
			invalid_tiles.append(tile)
			pathfinding.disablePoint(tile)
			builder.setPathfinding(pathfinding)
			builder.stop()

		isBuilding = false
		resetBuildPlacement()

func reacedBuildingPlace(tar):
	var destinationPos = buildingPlacement.map_to_world(buildDestTile, false)
	if builder.position.distance_to(destinationPos + Vector2(16, 16)) <= 32:
		return true

func _unhandled_input(event):
	var mousePos = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			deselectUnit(event)
			if canPlace:
				placeBuilding(event)
			return
		if dragging:
			selectUnit(event)
			return
		
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		if event.is_pressed():
			pointer.update_status(mousePos, true)
			return
		
		#if mouse is release
		pointer.update_status(mousePos, false)
		if selectedBuilder != null:
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

func deselectUnit(event):
	if selectedBuilder != null:
		selectedBuilder.deselect()
	selectedBuilder = null
	dragging = true
	dragStart = get_global_mouse_position()

func selectUnit(event):
	
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
		if shape.collider.name == builder.name:
			selectedBuilder = shape.collider
			selectedBuilder.select()
			
			#hide/unhide ui control
			uiControl.visible = !uiControl.visible

func placeBuilding(event):
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
