extends ProgressBar

func _ready():
	pass # Replace with function body.

func onHealthUpdate(health):
	value = health
	
func onMaxHealthUpdate(maxHealth):
	max_value = maxHealth
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
