extends Area2D

export var speed = 300
export var steer_force = 10
var damage = 1
var unitOwner = "ally"

var velocity = Vector2.ZERO
var target = null

func init(_transform, _target, _damage):
	global_transform = _transform
			
	velocity = transform.x * speed
	target = _target
	damage = _damage
	
func seek():
	var steer = Vector2.ZERO
	if target.get_ref():
		var desired = global_position.direction_to(target.get_ref().global_position) * speed
		steer = (desired - velocity).normalized() * steer_force
	
	return steer

func updateSprite():
	pass

func _physics_process(delta):
	velocity += seek() * delta
	rotation = velocity.angle()
	position += velocity * delta 
	
	updateSprite()
	
	if target.get_ref() == null || target == null:
		queue_free()

func _on_Arrow_body_entered(_body: Node2D):
	if _body.unitOwner == unitOwner:
		return
	if target != null && target.get_ref() != null:
		if target.get_ref().has_method("takeDamage") && target.get_ref().unitOwner != unitOwner && target.get_ref().currentHealth >= 0:
			if target.get_ref():
				if GlobalVar.debug:
					target.get_ref().takeDamage(damage)
					queue_free()
					return
				target.get_ref().rpc("takeDamage", damage)
				queue_free()


