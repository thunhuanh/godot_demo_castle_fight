extends Area2D


onready var swingAnim : AnimationPlayer = $AnimationPlayer

func attack():
	swingAnim.play("Swing")


func _on_Weapon_body_entered(body : Node2D):
	if body.has_method("takeDamage"):
		body.takeDamage(1)
