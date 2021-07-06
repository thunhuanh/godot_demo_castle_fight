extends StaticBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var selected = false
export var spawnRate = 5
export var maxHealth = 200
export var maxSoldier = 4
export var unitOwner = "ally"

var currentHealth = 0
var spawnProgress = 0 
var numOfSoldier = 0
var collisionRadius = 8

var enemyMainHouseDest : Vector2 = Vector2.ZERO

onready var spawnTimer : Timer = $SpawnTimer
onready var buildTimer : Timer = $BuildTimer
onready var progress : TextureProgress = $SpawnProgress
onready var buildProgress : ProgressBar = $BuildProgress
onready var healthBar : ProgressBar = $HealthBar
onready var sprite : Sprite = $Sprite
onready var soldier = preload("res://Scenes/melee.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	# set enemy house tile
	if unitOwner == "enemy":
		enemyMainHouseDest = Vector2(160, 250)
	else :
		enemyMainHouseDest = Vector2(840, 260)
		
	
	# build process
	buildTimer.set_wait_time(maxHealth / 20)
	buildTimer.one_shot = true
	buildTimer.start()
	
	# spawn soldier
	spawnTimer.set_wait_time(1)
	spawnTimer.one_shot = false;
	
	# progress
	progress.visible = false
	progress.max_value = spawnRate
	progress.value = spawnRate
	progress.step = 1
	
	# health bar
	healthBar.set_max(maxHealth)
	
	# build progress
	buildProgress.max_value = maxHealth / 10
	buildProgress.value = 0
	buildProgress.step = 0
	
	healthBar.visible = false

	return

func _process(delta):
	if currentHealth == maxHealth:
		progress.set_value(spawnProgress)

	updateSprite()
	buildProgress.value += delta

func updateSprite():
	# correct color
	if unitOwner == "enemy":
		sprite.modulate = Color(255, 0, 0)
	
func select():
	selected = true

remotesync func takeDamage(damage: float) -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0 :
		queue_free()

func _on_Timer_timeout():
	# spawn soldier
	spawnProgress += 1
	var isDoneBuilding = currentHealth == maxHealth 
	var isNumOfSoldierValid = numOfSoldier <= maxSoldier
	if isDoneBuilding && isNumOfSoldierValid && spawnProgress == spawnRate:
		var newSoldier = soldier.instance()
		
		newSoldier.position = position + Vector2(16, 48)
		newSoldier.unitOwner = unitOwner
		newSoldier.setPathfinding(get_parent().get_parent().get_parent().pathfinding)
		
		get_parent().get_parent().get_child(3).add_child(newSoldier)
		newSoldier.setDest(enemyMainHouseDest)

		numOfSoldier += 1
		
		# reset progress bar
		progress.value = spawnRate
		spawnProgress = 0
	
	if progress.visible && numOfSoldier >= maxSoldier:
		progress.visible = false

	if numOfSoldier == maxSoldier:
		spawnTimer.queue_free()

	pass # Replace with function body.

func _on_BuildTimer_timeout():
	# start spawn soldier
	spawnTimer.start()
	progress.visible = true
	
	# set health bar and delete buildTimer
	buildProgress.visible = false
	healthBar.set_value(maxHealth)
	currentHealth = maxHealth
	healthBar.visible = true
	buildTimer.queue_free()
	pass # Replace with function body.
