extends StaticBody2D

onready var healthBar : TextureProgress = $HealthBar
export var maxHealth = 50
export var unitOwner = "ally"
var currentHealth = maxHealth
var collisionRadius = 20
# Called when the node enters the scene tree for the first time.
func _ready():
	healthBar.set_max(maxHealth)
	healthBar.set_value(currentHealth)

func takeDamage(damage) -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0 :
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
