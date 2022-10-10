extends soldier

func _ready():
	._ready()
	
func _physics_process(delta):
	.updateMovementAndAction(delta)
	.updateSprite()

func _on_StopTimer_timeout():
	._on_StopTimer_timeout()

func attack():
	if attackTarget != null && attackTarget.get_ref() != null:
		if attackTarget.get_ref().has_method("takeDamage") && attackTarget.get_ref().currentHealth > 0:
			if attackTarget.get_ref():
				if GlobalVar.debug:
					attackTarget.get_ref().takeDamage(.calculateDamge())
					return
				attackTarget.get_ref().rpc("takeDamage", .calculateDamge())
				
func _on_VisionRange_body_entered(body: Node2D):
	._on_VisionRange_body_entered(body)
	
func _on_VisionRange_body_exited(body: Node2D):
	._on_VisionRange_body_exited(body)


func _on_Sprite_animation_finished():
	if sprite.animation == "attack":
		attack()

