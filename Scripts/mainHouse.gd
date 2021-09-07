extends StaticBody2D

onready var healthBar : TextureProgress = $HealthBar
export var maxHealth = 500
export var unitOwner = "ally"
var currentHealth = maxHealth
var collisionRadius = 20
onready var gameNode = get_node("/root/Main/Game")

# Called when the node enters the scene tree for the first time.
func _ready():
	healthBar.step = 0
	healthBar.set_max(maxHealth)
	healthBar.set_value(currentHealth)

remote func takeDamage(damage : float, _unitOwner: String = "s") -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0 :
		var destroyed_main_house_texture = load("res://Assets/"+get_name()+"-destroyed.png")
		$Sprite.set_texture(destroyed_main_house_texture)
		setGameStatusText("VICTORY!")
		rpc("setGameStatusText", "LOSS!")
		rpc("pauseGame")
		
remote func setGameStatusText(_text: String):
	gameNode.get_node_or_null("UI/Control/Popup/VBoxContainer/VBoxContainer/StatusText").text = _text
	gameNode.get_node_or_null("UI/Control/Popup").popup_centered()

remotesync func pauseGame():
	get_tree().paused = true
