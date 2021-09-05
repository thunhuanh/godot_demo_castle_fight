extends Node2D

onready var swingAnim : AnimationPlayer = $AnimationPlayer

remotesync func attack():
	swingAnim.play("Swing")

