extends StaticBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var selected = false
export var spawnRate = 5
var maxSoldier = 5
var numOfSoldier = 0
onready var timer = $Timer
onready var progress = $ProgressBar
onready var soldier = preload("res://Scenes/soldier.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	# spawn soldier
	timer.set_wait_time(spawnRate)
	timer.one_shot = false;
	timer.start()
	
	progress.max_value = spawnRate
	progress.value = spawnRate
	progress.step = 0
	return

func _process(delta):
	progress.value -= delta

func select():
	selected = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	# spawn soldier
	if numOfSoldier <= maxSoldier:
		var newSoldier = soldier.instance()
		newSoldier.position = position + Vector2(32, 16)
		get_parent().add_child(newSoldier)
		newSoldier.move_to(get_global_mouse_position())
		numOfSoldier += 1
	# reset progress bar
		progress.value = spawnRate
	
	if progress.visible and numOfSoldier >= maxSoldier:
		progress.visible = false
	
	pass # Replace with function body.
