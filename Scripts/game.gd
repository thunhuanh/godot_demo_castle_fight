extends Node2D

const MAXIMUM_WORK_DISTANCE := 16

var dragging = false
var selected = []
var dragStart = Vector2.ZERO
var selectedRect = RectangleShape2D.new()
var canPlace = false
var invalid_tiles = []
var buildDestination = Vector2.ZERO
var isBuilding = false

onready var building = preload("res://Scenes/building.tscn")

onready var selectRectDraw = $selectionRect
onready var pointer = $pointer
onready var builder = $buildings/builder

func _process(delta):
	if builder.reached(buildDestination) and isBuilding:
		var tile = $building_placement.world_to_map(buildDestination)

		var newBuilding = building.instance()
		newBuilding.position = tile * Vector2(32, 32)
		
		if not tile in invalid_tiles:
			$buildings.add_child(newBuilding)
			invalid_tiles.append(tile)
		isBuilding = false
		resetBuildPlacement()

func _unhandled_input(event):
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
			pointer.update_status(get_global_mouse_position(), true)
			return
		
		#if mouse is release
		pointer.update_status(get_global_mouse_position(), false)
		for unit in selected:
			unit.collider.move_to(get_global_mouse_position())
			
		return
	
	if event.is_action_pressed("ui_cancel"):
		resetBuildPlacement()
	
	if event is InputEventMouseMotion:
		if canPlace:
			$building_placement.clear()
			var tile = $building_placement.world_to_map(event.position)
			if not tile in invalid_tiles:
				$building_placement.set_cell(tile.x, tile.y, 0)
			else:
				$building_placement.set_cell(tile.x, tile.y, 1)
		if dragging:
			selectRectDraw.update_status(dragStart, get_global_mouse_position(), dragging)

func deselectUnit(event):
	for unit in selected:
		unit.collider.deselect()
	selected = []
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
	
	#get all intersect shape
	selected = space.intersect_shape(query)
	
	#select unit inside rectangle
	for unit in selected:
		unit.collider.select()

func placeBuilding(event):
	var global_mouse_position := get_global_mouse_position()
	
	var is_close_to_player := (
		global_mouse_position.distance_to(builder.global_position)
		< MAXIMUM_WORK_DISTANCE
	)
	
	resetBuildPlacement()
	var tile = $building_placement.world_to_map(event.position)
	
	var newBuilding = building.instance()
	newBuilding.position = tile * Vector2(32, 32)
	if not tile in invalid_tiles && is_close_to_player:
		$buildings.add_child(newBuilding)
		invalid_tiles.append(tile)
	elif not tile in invalid_tiles:
		buildDestination = global_mouse_position
		isBuilding = true
		builder.move_to(global_mouse_position)
		
		

func resetBuildPlacement():
	$building_placement.clear()
	canPlace = false

func _on_Button_pressed():
	$building_placement.clear()
	canPlace = !canPlace
