extends soldier

export var arrow : PackedScene

func _ready():
	._ready()
#	if unitOwner == 'enemy' and sprite.material.get_shader_param("isEnemy") == false:
#		sprite.material.set_shader_param("isEnemy", true)

func _physics_process(_delta):
	.updateMovementAndAction(_delta)
	.updateSprite()

func _on_StopTimer_timeout():
	._on_StopTimer_timeout()

func attack():
	if attackTarget != null && attackTarget.get_ref() != null:
		var arrowInstance = arrow.instance()
		arrowInstance.unitOwner = unitOwner
		arrowInstance.scale.x = sign(attackTarget.get_ref().position.x - position.x)
		
		var damage = .calculateDamge()
		var arrowPos = position + Vector2(8 * sign(attackTarget.get_ref().position.x - position.x), -8) 
			
		arrowInstance.init(Transform2D(rotation, arrowPos), attackTarget, damage)
		get_parent().get_parent().get_child(3).add_child(arrowInstance)

func _on_VisionRange_body_entered(body: Node2D):
	._on_VisionRange_body_entered(body)
	
func _on_VisionRange_body_exited(body: Node2D):
	._on_VisionRange_body_exited(body)

func _on_Sprite_animation_finished():
	if sprite.animation == "attack":
		attack()
