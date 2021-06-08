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
const moveThreshold : float = 2.0
var pathfinding : Pathfinding
var unitOwner : String = "ally"

var attackTarget : Soldier
var attackRange = 100

onready var stopTimer : Timer = $StopTimer
onready var weapon : Node2D = $Weapon
onready var sprite : Sprite = $Sprite
onready var healthBar : TextureProgress = $HealthBar

func _ready():
	dest = position
	finalDest = position
	healthBar.max_value = maxHealth
	healthBar.value = currentHealth	
	# update pathfinding
	
func _process(_delta):
	connect("updatePathfinding", self, "setPathfinding")
	if unitOwner == "enemy":
		sprite.modulate = Color(0, 0, 1) # blue shade

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	set_physics_process(true)
	
func _physics_process(_delta):
	if attackTarget:
		dest = attackTarget.position
	
	var enemy = cloestEnemyWithinRange()
	if enemy:
		attackTarget = enemy
		weapon.attack()
	
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
		queue_free()

func updateSprite():
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func _on_StopTimer_timeout():
	if get_slide_count():
		if lastPosition.distance_to(dest) < lastPosition.distance_to(dest) + moveThreshold:
			dest = position

func compareDistance(target_a : Node2D, target_b : Node2D):
	if position.distance_to(target_a.position) < position.distance_to(target_b.position):
		return true
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
		if cloestEnemy().position.distance_to(position) < attackRange:
			return cloestEnemy()
		else:
			return null
	else:
		return null

func _on_VisionRange_body_entered(body : Node2D):
	if body.get("unitOwner") != unitOwner:
		possibleTarget.append(body)

func _on_AnimationPlayer_animation_finished(_anim_name):
	if attackTarget:
		if attackTarget.has_method("takeDamage"):
			print(attackTarget.has_method("takeDamage"))
			attackTarget.takeDamage(1)
		
