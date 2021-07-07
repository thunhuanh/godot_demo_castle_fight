extends soldier

onready var arrow = preload("res://Scenes/Arrow.tscn")
var isAttack : bool = false

func _ready():
	._ready()
	attackRange = 700

func _physics_process(_delta):
	._physics_process(_delta)
	if isAttack == false:
		dest = finalDest
	# set attack target
	if cloestEnemy() != null :
		attackTarget = weakref(cloestEnemy())
		# move to target
		dest = position
		isAttack = true		
	
	if cloestEnemyWithinRange() != null:
		attackTarget = weakref(cloestEnemyWithinRange())
		# perform attack
		isAttack = true
		weapon.rpc("attack")
		return

	#reset velocity
	if isAttack == false:
		velocity = Vector2.ZERO
		if is_network_master():
			var path = pathfinding.getPath(global_position, dest)
			if path.size() > 0:
				if global_position.distance_to(path[0]) > targetMax:
					velocity = position.direction_to(path[0]) * speed
					if get_slide_count() and stopTimer.is_stopped():
						stopTimer.start()
						lastPosition = global_position
			rset_unreliable("slavePosition", position)
		else:
			position = slavePosition
		# moving
		velocity = move_and_slide(velocity)

func _on_StopTimer_timeout():
	._on_StopTimer_timeout()

func _on_AnimationPlayer_animation_finished(_anim_name):
	if attackTarget != null && attackTarget.get_ref() != null:
		var arrowInstance = arrow.instance()
		arrowInstance.init(transform, attackTarget)
		arrowInstance.unitOwner = unitOwner
		
		get_node("/root/world/Game/instanceSort/entities").add_child(arrowInstance)

func _on_VisionRange_body_entered(body: Node2D):
	._on_VisionRange_body_entered(body)
	
func _on_VisionRange_body_exited(body: Node2D):
	._on_VisionRange_body_exited(body)

