extends KinematicBody2D
class_name Soldier

export var speed : float = 40.0
export var maxHealth = 5

var currentHealth = 5
var selected : bool = false
var dest : Vector2 = Vector2.ZERO
var finalDest : Vector2 = Vector2.ZERO
var velocity : Vector2 = Vector2.ZERO
var targetMax = 1
var lastPosition : Vector2
var possibleTarget = []
const moveThreshold : float = 1.0
var pathfinding : Pathfinding
var unitOwner : String = "ally"

var attackTarget : Node2D = null
var attackRange = 30

onready var stopTimer : Timer = $StopTimer
onready var weapon : Node2D = $Weapon
onready var sprite : Sprite = $Sprite
onready var weaponSprite : Sprite = $Weapon/SpearSprite
onready var healthBar : TextureProgress = $HealthBar
onready var world : Node2D = get_node("/root/world")


func _ready():
	dest = position
	finalDest = position
	healthBar.max_value = maxHealth
	healthBar.value = currentHealth	
	world.connect("updatePathfinding", self, "setPathfinding")
	# update pathfinding
	
func updateSprite():
	if unitOwner == "enemy":
		weaponSprite.scale.x = -1
		sprite.modulate = Color(0, 0, 1) # blue shade

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	
func _physics_process(_delta):
	dest = finalDest
	if attackTarget:
		dest = attackTarget.position
	
	if possibleTarget.size() > 0:
		var enemy = cloestEnemyWithinRange()
		if enemy != null:
			attackTarget = enemy
			weapon.attack()
		else:
			attackTarget = null

	
	#reset velocity
	velocity = Vector2.ZERO
	var path = pathfinding.getPath(global_position, dest)

	if path.size() > 0:
		if position.distance_to(path[0]) > targetMax:
			velocity = position.direction_to(path[0]) * speed
			if get_slide_count() and stopTimer.is_stopped():
				stopTimer.start()
				lastPosition = position
	
	velocity = move_and_slide(velocity)

	updateSprite()	

	
func setDest(_dest):
	dest = _dest
	finalDest = _dest

func move_to(tar):
	dest = tar
	
func move_along_path(path):
	for p in path:
		move_to(p)

func stop():
	velocity = Vector2.ZERO
	dest = position

func takeDamage(damage: int) -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0:
		if possibleTarget.has(self):
			possibleTarget.erase(self)
		queue_free()
		
func _on_StopTimer_timeout():
	if get_slide_count():
		if lastPosition.distance_to(dest) < lastPosition.distance_to(dest) + moveThreshold:
			dest = position

func compareDistance(target_a : Node2D, target_b : Node2D):
	if position && target_a && target_b:
		if position.distance_to(target_a.position) < position.distance_to(target_b.position):
			return true
		else:
			return false
	else:
		return false

func cloestEnemy() -> Soldier:
	if possibleTarget.size() > 0:
		possibleTarget.sort_custom(self, "compareDistance")
		attackTarget = possibleTarget[0]
		return possibleTarget[0]
	else:
		return null

func cloestEnemyWithinRange() -> Soldier:
	if cloestEnemy():
		if cloestEnemy().position.distance_to(position) <= attackRange:
			return cloestEnemy()
		else:
			return null
	else:
		return null

func _on_VisionRange_body_entered(body : Node2D):
	if body.get("unitOwner") != unitOwner && not body is Builder && not possibleTarget.has(body):
		possibleTarget.append(body)

func _on_AnimationPlayer_animation_finished(_anim_name):
	if attackTarget:
		if attackTarget.has_method("takeDamage") && attackTarget.currentHealth > 0:
			attackTarget.takeDamage(1)
		else: 
			pass

func _on_VisionRange_body_exited(body: Node2D):
	if possibleTarget.has(body):
		possibleTarget.erase(body)
