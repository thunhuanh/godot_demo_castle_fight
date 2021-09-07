extends Node2D

var amount = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.set_text(str(amount))
	
	$Tween.interpolate_property(self, 'position', position, position + Vector2(0, -4), 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func _on_Tween_tween_all_completed():
	queue_free()
