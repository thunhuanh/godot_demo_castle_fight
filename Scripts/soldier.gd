extends KinematicBody2D
class_name soldier

export var speed : float = 40.0
export var attackRange = 30
export var maxHealth : float = 10
export var minDamage : float  = 1
export var maxDamage : float  = 3
export var unitOwner : String = "ally"
export var baseCritChance : float = 0.075
export var baseCritMultiplier : float = 1.5
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
var type : String = "melee"

onready var stopTimer : Timer = $StopTimer
onready var weapon : Node2D = $Weapon
onready var sprite : Sprite = $Sprite
onready var weaponSprite : Sprite = $Weapon/WeaponSprite
onready var healthBar : TextureProgress = $HealthBar
onready var avoidRay : Node2D = $AvoidRayCast
onready var rayFront : RayCast2D = $AvoidRayCast/Front
onready var game : Node2D = get_node("/root/world/Game")

func _ready():
	dest = global_position
	finalDest = global_position
	healthBar.max_value = maxHealth
	currentHealth = maxHealth
	healthBar.value = currentHealth	
	
	if not game.is_connected("updatePathfinding", self,  "setPathfinding"):
		game.connect("updatePathfinding", self, "setPathfinding")
	# update pathfinding

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding

func updateMovementAndAction(_delta):
	dest = finalDest
	isAttacking = false
	# set attack target
	if is_network_master():
		rset_unreliable("slavePosition", position)
	else:
		position = slavePosition
	handleAttack()
	handleMovement()

func handleMovement():
	if !isAttacking:
		velocity = Vector2.ZERO
		moveAlongPath()
		moveWithAvoidance()

func handleAttack():
	# engaging
	if cloestEnemy() != null:
		attackTarget = weakref(cloestEnemy())
		# move to target
		if type == "melee":
			moveTo(attackTarget.get_ref().global_position)
			
	if cloestEnemyWithinRange() != null:
		attackTarget = weakref(cloestEnemyWithinRange())
		# perform attack
		weapon.rpc("attack")
		isAttacking = true

func setDest(_dest : Vector2):
	dest = _dest
	finalDest = _dest

func moveTo(tar):
	velocity = Vector2.ZERO
	velocity = position.direction_to(tar) * speed
	moveWithAvoidance()

func moveAlongPath():
	var path = pathfinding.getPath(global_position, dest)
	if path.size() > 0:
		if global_position.distance_to(path[0]) > targetMax:
			velocity = position.direction_to(path[0]) * speed
			handleReachedTarget()

func handleReachedTarget():
	if get_slide_count() and stopTimer.is_stopped():
		stopTimer.start()
		lastPosition = global_position

func moveWithAvoidance():
	avoidRay.rotation = velocity.angle()
	if obstacleAhead() and rayFront.get_collider().unitOwner == unitOwner:
		var viableRay = getViableRay()
		if viableRay != null:
			velocity = sign(velocity.x) * Vector2.RIGHT.rotated(avoidRay.rotation + viableRay.rotation) * speed

	velocity = move_and_slide(velocity)

func obstacleAhead() -> bool:
	return rayFront.is_colliding()

func getViableRay() -> RayCast2D:
	for ray in avoidRay.get_children():
		if !ray.is_colliding() or (ray.get_collider().unitOwner != unitOwner):
			return ray
	return null

func stop():
	velocity = Vector2.ZERO
	dest = global_position

remotesync func takeDamage(_damage: int) -> void:
	currentHealth -= _damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0:
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
		if body.get("unitOwner") != unitOwner && not possibleTarget.has(body):
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
