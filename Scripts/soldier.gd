extends KinematicBody2D
class_name soldier

export var speed : float = 40.0
export var attackRange = 30
export var maxHealth  = 10
export var damage  = 1
var currentHealth = maxHealth
var unitOwner : String = "ally"

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

onready var stopTimer : Timer = $StopTimer
onready var weapon : Node2D = $Weapon
onready var sprite : Sprite = $Sprite
onready var weaponSprite : Sprite = $Weapon/WeaponSprite
onready var healthBar : TextureProgress = $HealthBar
onready var game : Node2D = get_node("/root/world/Game")

func _ready():
	dest = global_position
	finalDest = global_position
	healthBar.max_value = maxHealth
	currentHealth = maxHealth
	healthBar.value = currentHealth	
	if not game.is_connected("updatePathfinding", self,  "setPathfinding"):
		var err = game.connect("updatePathfinding", self, "setPathfinding")
		if err:
			print(err)
	# update pathfinding
func updateSprite():
	# correct color
	if unitOwner == "enemy":
		weaponSprite.scale.x = -1
		sprite.modulate = Color(255, 0, 0) # red shade

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	
func _physics_process(_delta):
	updateSprite()	

func updateMovementAndAction():
	dest = finalDest
	# set attack target
	if cloestEnemy() != null :
		attackTarget = weakref(cloestEnemy())
		# move to target
		dest = attackTarget.get_ref().global_position
	
	if cloestEnemyWithinRange() != null:
		attackTarget = weakref(cloestEnemyWithinRange())
		# perform attack
		weapon.rpc("attack")

	#reset velocity
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
	velocity = move_and_slide(velocity)
	
	
func setDest(_dest : Vector2):
	dest = _dest
	finalDest = _dest

func move_to(tar):
	dest = tar
	
func move_along_path(path):
	for p in path:
		move_to(p)

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
		attackTarget = weakref(possibleTarget[0])
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
