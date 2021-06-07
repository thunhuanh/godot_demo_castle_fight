extends KinematicBody2D

var selected : bool = false
var dest : Vector2 = Vector2.ZERO
var velocity : Vector2 = Vector2.ZERO
var pathfinding : Pathfinding
export var speed : float = 40.0
export var maxHealth = 5
var currentHealth = 0
const moveThreshold : float = 0.8

var targetMax = 1
var lastPosition : Vector2

onready var stopTimer : Timer = $StopTimer
onready var weapon : Area2D = $Weapon
onready var sprite : Sprite = $Sprite


func _ready():
	dest = position

func takeDamage(damage: int) -> void:
	currentHealth -= damage
	if currentHealth <= 0:
		queue_free()

func updateSprite():
	print(velocity)
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func _physics_process(delta):
	velocity = Vector2.ZERO
	
	if position.distance_to(dest) > targetMax:
		velocity = position.direction_to(dest) * speed
		if get_slide_count() and stopTimer.is_stopped():
			stopTimer.start()
			lastPosition = position

	velocity = move_and_slide(velocity)
	
	updateSprite()
	
func move_to(tar):
	dest = tar
	
func stop():
	velocity = Vector2.ZERO
	dest = position

func _on_StopTimer_timeout():
	if get_slide_count():
		if lastPosition.distance_to(dest) <= lastPosition.distance_to(dest) + moveThreshold:
			dest = position
