extends StaticBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var selected = false
export var spawnRate = 5
var spawnTick = 0
export var maxHealth = 100
var buildTime = 5
var currentHealth = 0
var maxSoldier = 5
var numOfSoldier = 0
onready var spawnTimer : Timer = $SpawnTimer
onready var buildTimer : Timer = $BuildTimer
onready var progress : TextureProgress = $SpawnProgress
onready var buildProgress : ProgressBar = $BuildProgress
onready var healthBar : ProgressBar = $HealthBar
onready var soldier = preload("res://Scenes/soldier.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	# build process
	buildTimer.set_wait_time(maxHealth / 10)
	buildTimer.one_shot = true
	buildTimer.start()
	
	# spawn soldier
	spawnTimer.set_wait_time(1)
	spawnTimer.one_shot = false;
	
	progress.visible = false
	progress.max_value = spawnRate
	progress.value = spawnRate
	progress.step = 1
	
	buildProgress.max_value = maxHealth / 10
	buildProgress.value = 0
	buildProgress.step = 0
	
	healthBar.visible = false

	return

func _process(delta):
	if currentHealth == maxHealth:
		progress.set_value(spawnTick)

	buildProgress.value += delta

func select():
	selected = true

func takeDamage(damage: int) -> void:
	healthBar.set_value(healthBar.get_value() - damage)

func _on_Timer_timeout():
	spawnTick += 1
	# spawn soldier
	var isDoneBuilding = currentHealth == maxHealth
	if numOfSoldier <= maxSoldier && isDoneBuilding && spawnTick == spawnRate:
		var newSoldier = soldier.instance()
		newSoldier.position = position + Vector2(32, 16)
		get_parent().add_child(newSoldier)
		newSoldier.move_to(get_global_mouse_position())
		numOfSoldier += 1
	# reset progress bar
		progress.value = spawnRate
		spawnTick = 0
	
	if progress.visible and numOfSoldier >= maxSoldier:
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
