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

signal updatePathfinding(pathfinding)

export var building = preload("res://Scenes/building.tscn")

var builder : Builder = null
var uniqueId = 0

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

	# connect signal for multiplayer
	pathfinding.genMap(env)
	var mainHouseTile = env.world_to_map(mainHouse.position)
	var enemyHouseTile = env.world_to_map(enemyHouse.position)
	invalid_tiles = invalid_tiles + [mainHouseTile, mainHouseTile + Vector2(-1, 1),
	 mainHouseTile + Vector2(0, 1), enemyHouseTile, enemyHouseTile + Vector2(-1, 0),
	 enemyHouseTile + Vector2(1, 0)]

func _process(_delta):
	if builder == null && get_tree().has_network_peer():
		if is_network_master():
			uniqueId = 1
		else:
			uniqueId = get_tree().get_network_unique_id()

		builder = get_node_or_null("instanceSort/" + str(uniqueId))
	
	# checked if player reach building place
	if buildDestTile != null and reachedBuildingPlace() and isBuilding and builder != null:
		rpc("buildBuilding", buildDestination, builder.unitOwner)
		
remotesync func buildBuilding(buidDest: Vector2, unitOwner : String = "ally"):
	var tile = buildingPlacement.world_to_map(buidDest)

	var newBuilding = building.instance()
	newBuilding.unitOwner = unitOwner
	newBuilding.position = tile * Vector2(32, 32)
		
	if not tile in invalid_tiles :
		buildings.add_child(newBuilding)
		# remove from pathfinding
		invalid_tiles.append(tile)
		pathfinding.disablePoint(tile)

		# emit signal to soldier to update pathfinding graph
		emit_signal("updatePathfinding", pathfinding)
		if builder != null:
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
				placeBuilding(mousePos)
			return
		if dragging:
			selectUnit()
			return

	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		if event.is_pressed():
			pointer.update_status(mousePos, true)
#			return
			
		pointer.update_status(mousePos, false)
		if selectedBuilder != null:
			#if mouse is release
			selectedBuilder.move_to(mousePos)

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

remotesync func placeBuilding(_buildDest: Vector2):
	buildDestination = _buildDest
	var is_close_to_player : bool = (
		buildDestination.distance_to(builder.global_position)
		<= MAXIMUM_WORK_DISTANCE
	)

	var tile = buildingPlacement.world_to_map(buildDestination)
	buildDestTile = tile

	#prepare tile for placing building
	if is_close_to_player:
		rpc("buildBuilding", buildDestination, builder.unitOwner)
	else:
		isBuilding = true
		builder.move_to(buildDestination)
		
	buildingPlacement.clear()
	
func resetBuildPlacement():
	buildingPlacement.clear()
	canPlace = false

func _on_Button_pressed():
	buildingPlacement.clear()
	canPlace = !canPlace
