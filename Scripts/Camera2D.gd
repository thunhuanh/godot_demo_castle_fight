extends Camera2D

export var Speed = 5.0
var controlNode = null

func _ready():
	pass 

func _process(delta):
	if controlNode:
		position.x = lerp(position.x, position.x + controlNode.output.x * Speed * zoom.x * 1.5, Speed * delta * zoom.x * 1.5)
		position.y = lerp(position.y, position.y + controlNode.output.y * Speed * zoom.y * 1.5, Speed * delta * zoom.y * 1.5)
	else:
		var inputX = (int(Input.is_action_pressed("ui_right")) 
			- int(Input.is_action_pressed("ui_left")))
		
		var inputY = (int(Input.is_action_pressed("ui_down")) 
			- int(Input.is_action_pressed("ui_up")))
		position.x = lerp(position.x, position.x + inputX * Speed * zoom.x * 1.5, Speed * delta * zoom.x * 1.5)
		position.y = lerp(position.y, position.y + inputY * Speed * zoom.y * 1.5, Speed * delta * zoom.y * 1.5)

