extends KinematicBody2D

var selected = false
var dest = Vector2.ZERO
var velocity = Vector2.ZERO
export var speed = 40.0

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
	
func reached(tar):
	if position.distance_to(tar) <= 1:
		return true

func select():
	selected = true
	$Box.visible = true

func deselect():
	selected = false
	$Box.visible = false

