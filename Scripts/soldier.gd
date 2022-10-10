extends KinematicBody2D
class_name soldier

export var speed : float = 40.0
export var attackRange = 30
export var maxHealth : float = 10
export var minDamage : float  = 1
export var maxDamage : float  = 3
export var unitOwner : String = "ally" setget setUnitOwner
export var baseCritChance : float = 0.075
export var baseCritMultiplier : float = 1.5
export var reward = 1
export var footDust : PackedScene
export var type : String = "melee"

var avoidForce = 20

var currentHealth : float = maxHealth

var selected : bool = false
var dest : Vector2 = Vector2.ZERO
var finalDest : Vector2 = Vector2.ZERO
var velocity : Vector2 = Vector2.ZERO
var targetMax = 1
const moveThreshold : float = 1.0
var lastPosition : Vector2
var possibleTarget = []

remote var slavePosition : Vector2 = Vector2.ZERO

var pathfinding : Pathfinding

var collisionRadius = 0
var attackTarget = null
var isAttacking : bool = false
var isMoving : bool = false
var frameCount = 0

onready var stopTimer : Timer = $StopTimer
#onready var weapon : Node2D = get_node_or_null("./Weapon")
onready var sprite : AnimatedSprite = $Sprite
onready var healthBar : TextureProgress = $HealthBar
onready var avoidRay : Node2D = $AvoidRayCast
onready var rayFront : RayCast2D = $AvoidRayCast/Front
onready var game : Node2D = get_node_or_null("/root/Game")
onready var floatingCoin = preload("res://Scenes/FloatingCoin.tscn")
onready var animationPlayer = $AnimationPlayer

var avoidanceDir = 1 # up, each soldier has 1 avoidance direction, either up or down
var prevPos

func _ready():
	dest = global_position
	finalDest = global_position
	healthBar.max_value = maxHealth
	currentHealth = maxHealth
	healthBar.value = currentHealth	
	randomize()
	avoidanceDir = sign(rand_range(-1, 1))

	if game and not game.is_connected("updatePathfinding", self,  "setPathfinding"):
		var _err = game.connect("updatePathfinding", self, "setPathfinding")
	
	if unitOwner == 'enemy' and sprite.material.get_shader_param("isEnemy") == false:
		sprite.material.set_shader_param("isEnemy", true)
	# update pathfinding

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding

func updateMovementAndAction(_delta):
	dest = finalDest
	isAttacking = false
	handleAttack()
	# set attack target
#	if is_network_master():
	handleMovement()
#	rset("slavePosition", position)
#	else:
#		position = slavePosition

#func isMoving() -> bool:
#	var isMove = global_position != prevPos
#	prevPos = global_position
#	return isMove

func updateSprite():
	if isAttacking:
		sprite.play("attack")
	elif isMoving:
		sprite.play("walk")
		handleFootStepEmitDust()
	else:
		sprite.play("idle")
	
#	if weapon == null:
#		return
#
	if unitOwner == "enemy":
		sprite.scale.x = -1
		avoidRay.scale.x = -1
	
	if attackTarget and attackTarget.get_ref():
		sprite.scale.x = sign(attackTarget.get_ref().position.x - position.x)
	else:
		if velocity.x != 0:
			sprite.scale.x = sign(velocity.x)

func setUnitOwner(newUnitOwner):
	unitOwner = newUnitOwner
	if newUnitOwner == 'enemy' and sprite and sprite.material.get_shader_param("isEnemy") == false:
		sprite.material.set_shader_param("isEnemy", true)

func handleMovement():
	isMoving = true
	velocity = Vector2.ZERO
	if isAttacking == true:
		isMoving = false
		return

	moveWithAvoidance(dest)

func handleFootStepEmitDust():
	if footDust and frameCount == 10:
		var dust = footDust.instance()
		dust.emitting = true
		dust.global_position = global_position
		get_parent().get_parent().get_child(4).add_child(dust)
		frameCount = 0
	else:
		frameCount += 1

func handleAttack():
	# engaging
	if isAttacking:
#		playAttackAnimation()
		return

	if cloestEnemy() != null:
		attackTarget = weakref(cloestEnemy())
		# move to target
		if type == "melee":
			moveTo(attackTarget.get_ref().global_position)
	
	if cloestEnemyWithinRange() != null:
		attackTarget = weakref(cloestEnemyWithinRange())
		# perform attack
		isAttacking = true
#		playAttackAnimation()
#		if !GlobalVar.debug:
#			rpc("playAttackAnimation")
		
#		if weapon != null:
#			weapon.attack()
#			weapon.rpc("attack")

func playAttackAnimation():
	sprite.play()
	sprite.play("attack")

func setDest(_dest : Vector2):
	dest = _dest
	finalDest = _dest

func moveTo(tar):
	moveWithAvoidance(tar)
#	velocity = Vector2.ZERO
#	velocity = position.direction_to(tar) * speed

func moveAlongPath():
	if pathfinding:
		var path = pathfinding.getPath(global_position, dest)
		if path.size() > 0:
			if global_position.distance_to(path[0]) > targetMax:
				velocity = position.direction_to(path[0]) * speed
				handleReachedTarget()
				return
	
	velocity = position.direction_to(dest) * speed
	velocity = move_and_slide(velocity)

func handleReachedTarget():
	if get_slide_count() and stopTimer.is_stopped():
		stopTimer.start()
		lastPosition = global_position

func moveWithAvoidance(target):
	var returnValues = obstacleAhead()
	var ahead : bool = returnValues[0]
	
	avoidRay.rotation = velocity.angle()

	var collider : Node2D = returnValues[1]
	var avoidance : Vector2 = Vector2.ZERO
	var steering : Vector2 = Vector2.ZERO

	if ahead == true and rayFront.get_collider().unitOwner == unitOwner:
		avoidance = (position + Vector2(rayFront.cast_to.y, rayFront.cast_to.y) - collider.position).normalized()
		if unitOwner == "enemy":
			avoidance.x *= -1
		avoidance = avoidance * avoidForce 
		steering = velocity + avoidance
		
		velocity = move_and_slide(truncate(velocity + steering, speed))
		return
		
	velocity = position.direction_to(target) * speed
	velocity = move_and_slide(velocity)

func truncate(vector: Vector2, maxValue):
	var vectorLegth = vector.length()
	if vectorLegth == 0:
		vectorLegth = 1
	var i = maxValue / vectorLegth
	i = min(i, 1.0)
	vector.y *= avoidanceDir # avoid in up or down direction
	return vector * i

func obstacleAhead() -> Array:
	return [rayFront.is_colliding(), rayFront.get_collider()]

func stop():
	velocity = Vector2.ZERO
	dest = global_position

remotesync func takeDamage(_damage: int) -> void:
	currentHealth -= _damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0:
		set_physics_process(false)
		# stop the soldier from moving further
		$CollisionShape2D.set_deferred("disabled", true)
		dest = global_position
		finalDest = global_position
#		if weapon:
#			weapon.hide()
		healthBar.hide()
		
		# play death animation
		animationPlayer.play("Die")
		
		if !GlobalVar.debug:
			GlobalVar.rpc("receiveReward", reward, unitOwner)
		else:
			GlobalVar.receiveReward(reward, unitOwner)
		
		# show coin receive
		var floatingCoinReceive = floatingCoin.instance()
		floatingCoinReceive.amount = reward
		add_child(floatingCoinReceive)
		# add timer wait 0.5 second before remove from scene tree
		yield(get_tree().create_timer(0.5), "timeout")
		# remove from scene tree
		queue_free()

func _on_StopTimer_timeout():
	if get_slide_count():
		if lastPosition.distance_to(dest) < lastPosition.distance_to(dest) + moveThreshold:
			dest = position

func compareDistance(target_a : Node2D, target_b : Node2D):
	if global_position && target_a && target_b:
		if global_position.distance_to(target_a.global_position) <= global_position.distance_to(target_b.global_position):
			return true
		else:
			return false
	else:
		return false

func cloestEnemy() -> Node2D:
	if possibleTarget.size() > 0:
		possibleTarget.sort_custom(self, "compareDistance")
		return possibleTarget[0]
	else:
		return null

func cloestEnemyWithinRange() -> Node2D:
	var enemy : Node2D = cloestEnemy()
	if enemy:
		if enemy.global_position.distance_to(global_position) - enemy.collisionRadius <= attackRange:
			return enemy
		else:
			return null
	else:
		return null

func _on_VisionRange_body_entered(body : Node2D):
	if not (body is Builder):
		if body.get("unitOwner") && body.get("unitOwner") != unitOwner && not possibleTarget.has(body):
			possibleTarget.append(body)

func _on_VisionRange_body_exited(body: Node2D):
	if possibleTarget.has(body):
		possibleTarget.erase(body)

func calculateDamge() -> float:
	var baseDamage = rand_range(minDamage, maxDamage)
	var isCrit : bool = randf() <= baseCritChance
	var finalDamge = baseDamage
	if isCrit:
		finalDamge *= baseCritMultiplier
	return finalDamge
