extends Camera2D

export var Speed = 5.0

func _ready():
	pass 

func _process(delta):
	
	var inputX = (int(Input.is_action_pressed("ui_right")) 
		- int(Input.is_action_pressed("ui_left")))
	
	var inputY = (int(Input.is_action_pressed("ui_down")) 
		- int(Input.is_action_pressed("ui_up")))
	
	position.x = lerp(position.x, position.x + inputX * Speed, Speed * delta)
	position.y = lerp(position.y, position.y + inputY * Speed, Speed * delta)
	pass
