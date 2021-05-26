extends KinematicBody2D

var selected = false
var dest = Vector2.ZERO
var velocity = Vector2.ZERO
var pathfinding : Pathfinding
export var speed = 20.0

func _ready():
	dest = position

func _physics_process(delta):
	#reset velocity
	velocity = Vector2.ZERO
	
	if position.distance_to(dest) > 1.5:
		velocity = position.direction_to(dest) * speed

	velocity = move_and_slide(velocity)
	
func move_to(tar):
	dest = tar
	
func stop():
	velocity = Vector2.ZERO
	dest = position

