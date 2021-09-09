extends StaticBody2D

var selected = false
export var spawnRate = 5
export var maxHealth : float = 200
export var buildTime = 10
export var maxSoldier = 1
export var unitOwner = "ally"
export var type = "barrack"
export var reward = 5
export var price = 5
export var soldier : PackedScene = null

var currentHealth : float = 0
var spawnProgress = 0 
var numOfSoldier = 0
var collisionRadius = 8

var enemyMainHouseDest : Vector2 = Vector2.ZERO

onready var spawnTimer : Timer = $SpawnTimer
onready var buildTimer : Timer = $BuildTimer
onready var spawnProgressBar : TextureProgress = $SpawnProgress
onready var buildProgress : ProgressBar = $BuildProgress
onready var healthBar : ProgressBar = $HealthBar
onready var sprite : Sprite = $Sprite

onready var buildFoundationTexture = preload("res://Assets/build_foundation.png")
var completeBuildingTexture 
var buildProgressRef = null


func _ready():
	# set starting texture (building foundation)
	sprite.set_texture(buildFoundationTexture)
	completeBuildingTexture = load("res://Assets/" + type + ".png")
	
	# correcting sprite position
	position = position + Vector2(16, 16)
	
	# set enemy house tile
	if unitOwner == "enemy":
		enemyMainHouseDest = Vector2(160, 250)
	else :
		enemyMainHouseDest = Vector2(840, 260)
	
	# build process
	buildTimer.set_wait_time(buildTime)
	buildTimer.one_shot = true
	buildTimer.start()
	
	# spawn soldier
	spawnTimer.set_wait_time(1)
	
	# spawnProgress
	spawnProgressBar.visible = false
	spawnProgressBar.max_value = spawnRate
	spawnProgressBar.value = spawnRate
	spawnProgressBar.step = 1
	
	# health bar
	healthBar.set_max(maxHealth)
	
	# build progress
	buildProgressRef = weakref(buildProgress)
	buildProgress.max_value = maxHealth
	
	healthBar.visible = false
	
	#correct color
	if unitOwner == 'enemy' and sprite.material.get_shader_param("isEnemy") == false:
		sprite.material.set_shader_param("isEnemy", true)

func _process(delta):
	if !buildProgressRef.get_ref():
		spawnProgressBar.set_value(spawnProgress)

#	updateSprite()
	
	if buildProgressRef.get_ref():
		buildProgress.value += (maxHealth / buildTime) * delta

func updateSprite():
	# correct color
	pass

func select():
	selected = true
	
remotesync func takeDamage(damage: float) -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0 :
		GlobalVar.rpc("receiveReward", reward, unitOwner)
		queue_free()

func _on_BuildTimer_timeout():
	# set texture
	sprite.set_texture(completeBuildingTexture)
	
	# start spawn soldier
	spawnTimer.start()
	spawnProgressBar.visible = true
	
	# set health bar and delete buildTimer
	buildProgress.visible = false
	
	# set health
	currentHealth = maxHealth
	healthBar.set_value(maxHealth)
	healthBar.visible = true
	
	buildProgress.queue_free()
	buildTimer.queue_free()

func _on_SpawnTimer_timeout():
	# spawn soldier
	spawnProgress += 1

	var isNumOfSoldierValid = true
	if isNumOfSoldierValid && spawnProgress == spawnRate:
		var newSoldier = soldier.instance()

		newSoldier.position = position + Vector2(0, 16)
		newSoldier.setUnitOwner(unitOwner)
		newSoldier.setPathfinding(get_parent().get_parent().get_parent().pathfinding)
		
		get_parent().get_parent().get_child(3).add_child(newSoldier)
		newSoldier.setDest(enemyMainHouseDest)

		numOfSoldier += 1
		
		# reset progress bar
		spawnProgress = 0
	
#	if spawnProgressBar.visible && numOfSoldier >= maxSoldier:
#		spawnProgressBar.visible = false
#
#	if numOfSoldier == maxSoldier:
#		spawnTimer.queue_free()

