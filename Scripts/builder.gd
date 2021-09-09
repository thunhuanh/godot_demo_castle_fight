extends KinematicBody2D
class_name Builder

var selected = false
var dest = Vector2.ZERO
var velocity = Vector2.ZERO
var pathfinding : Pathfinding
var playerID = ""
var playerName = ""
export var unitOwner = "ally"
export var controlNodePath : NodePath
onready var controlNode : Joystick = get_node(controlNodePath)

onready var sprite : Sprite = $Sprite
onready var nameTag : Label = $Label

remote var slavePosition = Vector2.ZERO
var prevPos

export var speed = 40.0
var isBuilding = false setget set_is_building
var isOnMobile = false

func _ready():
	dest = position
	
	if unitOwner == 'enemy' and sprite.material.get_shader_param("isEnemy") == false:
		sprite.material.set_shader_param("isEnemy", true)

func set_is_building(_isBuilding):
	isBuilding = _isBuilding

func setControlNode():
	controlNode = get_node(controlNodePath)
	
func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	set_physics_process(true)

func isMoving() -> bool:
	var isMove = global_position != prevPos
	prevPos = global_position
	return isMove


func _physics_process(_delta):
	updateSprite()
	
	#reset velocity
	velocity = Vector2.ZERO
		
	# playing on mobile
	if isOnMobile:
		handleMobileMovement()
	else:
		handleNormalMovement()
#	if position.distance_to(dest) > 1.5:
#		velocity = position.direction_to(dest) * speed
#	var path = []
#	if pathfinding:
#		path = pathfinding.getPath(global_position, dest)
#
#	if path.size() > 1:
#		if position.distance_to(path[0]) > 1.5:
#			velocity = position.direction_to(path[0]) * speed

func handleMobileMovement():
	if isBuilding:
		if get_tree().has_network_peer() && is_network_master():
			if position.distance_to(dest) > 1.5:
				velocity = position.direction_to(dest) * speed
			var path = []
			if pathfinding:
				path = pathfinding.getPath(global_position, dest)

			if path.size() > 1:
				if position.distance_to(path[0]) > 1.5:
					velocity = position.direction_to(path[0]) * speed
			rset_unreliable("slavePosition", position)
		else:
			position = slavePosition

		velocity = move_and_slide(velocity)
	else:
		if controlNode.is_working:
			velocity = move_and_slide(controlNode.output * speed)

func handleNormalMovement():
	if get_tree().has_network_peer() && is_network_master():
		if position.distance_to(dest) > 1.5:
			velocity = position.direction_to(dest) * speed
		var path = []
		if pathfinding:
			path = pathfinding.getPath(global_position, dest)

		if path.size() > 1:
			if position.distance_to(path[0]) > 1.5:
				velocity = position.direction_to(path[0]) * speed
		rset_unreliable("slavePosition", position)
	else:
		position = slavePosition
		
	velocity = move_and_slide(velocity)

func updateSprite():
	if nameTag.text == "":
		nameTag.text = playerName
	
	if !isMoving():
		sprite.play("idle")
	else:
		sprite.play("walk")

func move_to(tar):
	dest = tar
	
func move_along_path(path):
	for p in path:
		move_to(p)

func stop():
	velocity = Vector2.ZERO
	dest = position

func select():
	selected = true
	$Box.visible = true

func deselect():
	selected = false
	$Box.visible = false

