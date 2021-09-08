extends StaticBody2D

onready var healthBar : TextureProgress = $HealthBar
export var maxHealth = 500
export var unitOwner = "ally"
var currentHealth = maxHealth
var collisionRadius = 20
export var popupNodePath : NodePath = ""
onready var popup = get_node(popupNodePath)

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
	if popup:
		popup.get_node("VBoxContainer/VBoxContainer/StatusText").set_text(_text)
		popup.popup_centered()

remotesync func pauseGame():
	get_tree().paused = true
