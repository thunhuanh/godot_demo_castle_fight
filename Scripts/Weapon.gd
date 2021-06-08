extends Node2D

onready var swingAnim : AnimationPlayer = $AnimationPlayer

func attack():
	swingAnim.play("Swing")
