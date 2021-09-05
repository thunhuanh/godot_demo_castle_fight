extends soldier

onready var arrow = preload("res://Scenes/Arrow.tscn")

func _ready():
	._ready()
	type = "range"

func _physics_process(_delta):
	.updateMovementAndAction(_delta)
	updateSprite()

func updateSprite():
	if unitOwner == "enemy":
		weapon.scale.x = -1
		sprite.modulate = Color(255, 0, 0) # red shade
	
	if attackTarget and attackTarget.get_ref():
		weapon.scale.x = sign(attackTarget.get_ref().position.x - position.x)
	else:
		if velocity.x != 0:
			weapon.scale.x = sign(velocity.x)

func _on_StopTimer_timeout():
	._on_StopTimer_timeout()

func _on_AnimationPlayer_animation_finished(_anim_name):
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

