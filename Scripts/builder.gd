extends KinematicBody2D
class_name Builder

var selected = false
var dest = Vector2.ZERO
var velocity = Vector2.ZERO
var pathfinding : Pathfinding
export var speed = 40.0

func _ready():
	dest = position
	
func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	set_physics_process(true)
	
func _physics_process(_delta):
	#reset velocity
	velocity = Vector2.ZERO
	
	if position.distance_to(dest) > 1.5:
		velocity = position.direction_to(dest) * speed
	var path = pathfinding.getPath(global_position, dest)

	if path.size() > 1:
		if position.distance_to(path[0]) > 1.5:
			velocity = position.direction_to(path[0]) * speed
	velocity = move_and_slide(velocity)
	
func move_to(tar):
	dest = tar
	
func move_along_path(path):
	for p in path:
		move_to(p)

func stop():
	velocity = Vector2.ZERO
	dest = position
#state machine
	#idle dung yen : dest = position
	#attacking : play anim, deal damage
	#

func select():
	selected = true
	$Box.visible = true

func deselect():
	selected = false
	$Box.visible = false

