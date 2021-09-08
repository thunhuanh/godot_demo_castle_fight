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


var building : PackedScene = null
var buildingType = ""
var builder : Builder = null
var builderID = 0

onready var selectRectDraw : Node2D = $selectionRect
onready var pointer : Node2D = $pointer
onready var buildingPlacement : TileMap = $building_placement
onready var buildings  : YSort = $instanceSort/buildings
onready var mainHouse : StaticBody2D = $instanceSort/mainHouse1
onready var enemyHouse : StaticBody2D = $instanceSort/mainHouse2
onready var env : TileMap = $enviroment
onready var pathfinding : Pathfinding = $pathfinding
onready var joystick = $UserInterface/UI/JoystickLeft
onready var grid = $Grid

var builderScene = preload("res://Scenes/player.tscn")

func _ready():
	# check os
	if OS.get_name().to_lower() == 'ios' or OS.get_name().to_lower() == 'android':
		remove_child($camera)
	else:
		joystick.queue_free()
		remove_child($TouchScreenCamera)
	
	# connect signal for multiplayer
	pathfinding.genMap(env)
	var mainHouseTile = env.world_to_map(mainHouse.position)
	var enemyHouseTile = env.world_to_map(enemyHouse.position)
	invalid_tiles = invalid_tiles + [mainHouseTile, mainHouseTile + Vector2(-1, 1),
	 mainHouseTile + Vector2(0, 1), enemyHouseTile, enemyHouseTile + Vector2(-1, 0),
	 enemyHouseTile + Vector2(1, 0)]
	
	# connect building button to function
	for i in get_tree().get_nodes_in_group("building_buttons"):
		i.connect("pressed", self, "init_building", [i.get_name()])
	
#	builder = builderScene.instance()
#	builder.position = Vector2(512, 256)
#	$instanceSort.add_child(builder)

func _process(_delta):
	grid.on = canPlace
	
	if builder == null && get_tree().has_network_peer():
		builder = get_node("instanceSort/" + str(builderID))
		GlobalVar.unitOwner = builder.unitOwner
	
	# checked if player reach building place
	if buildDestTile != null and reachedBuildingPlace() and isBuilding and builder != null:
		rpc("buildBuilding", buildDestination, buildingType, builder.unitOwner)
#		buildBuilding(buildDestination, buildingType, builder.unitOwner)
	
remotesync func buildBuilding(buidDest: Vector2, _buildingType : String, unitOwner : String = "ally"):
	var tile = buildingPlacement.world_to_map(buidDest)

	building = load("res://Scenes/" + _buildingType + ".tscn")

	var newBuilding = building.instance()
	newBuilding.unitOwner = unitOwner
	newBuilding.position = tile * Vector2(32, 32)
	
	if GlobalVar.gold < newBuilding.price && unitOwner == builder.unitOwner:
		isBuilding = false
		resetBuildPlacement()
		return
	
	if not tile in invalid_tiles :
		buildings.add_child(newBuilding)
		if unitOwner == builder.unitOwner:
			GlobalVar.gold -= newBuilding.price
		# remove from pathfinding
		invalid_tiles.append(tile)
		pathfinding.disablePoint(tile)

		# emit signal to soldier to update pathfinding graph
		emit_signal("updatePathfinding", pathfinding)
		if builder != null:
			builder.setPathfinding(pathfinding)
			builder.stop()

		if unitOwner == builder.unitOwner:
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
			return
			
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
		if dragging and not (OS.get_name().to_lower() == 'ios' or OS.get_name().to_lower() == 'android'):
			selectRectDraw.update_status(dragStart, mousePos, dragging)

func deselectUnit():
	if selectedBuilder != null:
		selectedBuilder.deselect()
#		uiControl.visible = false
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
		rpc("buildBuilding", buildDestination, buildingType, builder.unitOwner)
#		buildBuilding(buildDestination, buildingType, builder.unitOwner)
	else:
		isBuilding = true
		builder.move_to(buildDestination)
	
	resetBuildPlacement()
	buildingPlacement.clear()

func resetBuildPlacement():
	buildingPlacement.clear()
	canPlace = false

func init_building(building_type):
	buildingType = building_type
	if isBuilding:
		return
	buildingPlacement.clear()
	canPlace = !canPlace


func _on_Button_pressed():
	pass # Replace with function body.


func _on_LobbyButton_pressed():
	get_tree().change_scene("res://Root.tscn")
	Gotm.lobby.leave()
	self.queue_free()
