extends Node2D



var isClick = false
var pos = Vector2.ZERO
onready var animation = $AnimatedSprite

func _ready():
	animation.connect("animation_finished", self, "animFinished")

func _process(_delta):
	if isClick:
		#reset animation
		animation.set_frame(0)
		
		#set pointer position
		position = pos
		set_visible(isClick)
		
		#play animation
		animation.play("default", false)

func animFinished():
	set_visible(false)

func update_status(_position, click):
	pos = _position
	isClick = click
	update()
