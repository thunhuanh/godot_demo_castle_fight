extends KinematicBody2D
class_name Builder

var selected = false
var dest = Vector2.ZERO
var velocity = Vector2.ZERO
var pathfinding : Pathfinding
var playerID = ""
var playerName = ""
export var unitOwner = "ally"

onready var nameTag : Label = $Label

remote var slavePosition = Vector2.ZERO

export var speed = 40.0

func _ready():
	dest = position
	
func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	set_physics_process(true)
	
func _physics_process(_delta):
	#reset velocity

	velocity = Vector2.ZERO
	if is_network_master():
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
	updateSprite()
	
func updateSprite():
	if nameTag.text == "":
		nameTag.text = playerName
	
	if unitOwner == "enemy":
		$Sprite.modulate = Color(255, 0, 0) # blue shade

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

