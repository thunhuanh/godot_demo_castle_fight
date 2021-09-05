extends Node

var gold = 10
var unitOwner = "ally"

remote func receiveReward(reward: int = 0, enemyUnitOwner: String = "enemy") -> void:
	if unitOwner != enemyUnitOwner:
		gold += reward
