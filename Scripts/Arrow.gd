extends Area2D

export var speed = 300
export var steer_force = 10
export var damage = 1

var unitOwner = "ally"

var velocity = Vector2.ZERO
var target = null

func init(_transform, _target):
	global_transform = _transform
	velocity = transform.x * speed
	target = _target
	
func seek():
	var steer = Vector2.ZERO
	if target.get_ref():
		var desired = (target.get_ref().position - position).normalized() * speed
		steer = (desired - velocity).normalized() * steer_force
	
	return steer

func _physics_process(delta):
	velocity += seek() * delta
	rotation = velocity.angle()
	position += velocity * delta 

func _on_Arrow_body_entered(_body: Node2D):
	if _body.unitOwner == unitOwner:
		return
	queue_free()
#	if target != null && target.get_ref() != null:
#		if target.get_ref().has_method("takeDamage") && target.get_ref().currentHealth >= 0:
#			target.get_ref().rpc_unreliable("takeDamage", damage)
#			queue_free()


