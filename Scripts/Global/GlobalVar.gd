extends Node

#var signal_server_url = "localhost:9080"
var signal_server_url = "wss://godot-signal-server.herokuapp.com"


var debug = true

var gold = 10
var unitOwner = "ally"
remote func receiveReward(reward: int = 0, enemyUnitOwner: String = "enemy") -> void:
	if unitOwner != enemyUnitOwner:
		gold += reward
