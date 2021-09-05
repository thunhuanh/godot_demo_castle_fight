extends Node2D

onready var shootAnim : AnimationPlayer = $AnimationPlayer

remotesync func attack():
	shootAnim.play("Shoot")

