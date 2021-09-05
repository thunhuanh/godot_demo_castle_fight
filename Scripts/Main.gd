extends Node2D

var OtherPlayer = preload("res://Scenes/player.tscn")
var Player = preload("res://Scenes/player.tscn")
var GameScene = preload("res://Scenes/Game.tscn")

#var signal_server_url = "localhost:9080"
var signal_server_url = "wss://godot-signal-server.herokuapp.com"

var player
var other_player

func _ready():
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_connected", self, "_on_game_connected")
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_disconnected", self, "_on_game_disconnected")
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_info", self, "_on_game_info")

func _on_game_connected(other_playerId):
	var game = GameScene.instance()

	player = Player.instance()
	var playerID = get_tree().get_network_unique_id()
	player.set_network_master(playerID)
	player.set_name(str(playerID))
	player.set_position(Vector2(512, 256))
	if MultiplayerClient.hosting :
		player.playerName = "BLUE"
		game.builderID = 1
	else:
		player.unitOwner = "enemy"
		player.playerName = "RED"
		game.builderID = 2
	game.get_node("instanceSort").add_child(player)

	other_player = OtherPlayer.instance()
	other_player.set_name(str(other_playerId))
	other_player.set_network_master(other_playerId)
	other_player.set_position(Vector2(512, 256))
	if MultiplayerClient.hosting :
		other_player.unitOwner = "enemy"
		other_player.playerName = "RED"
	else:
		other_player.unitOwner = "ally"
		other_player.playerName = "BLUE"
		
	game.get_node("instanceSort").add_child(other_player)
	
	add_child(game)
	
	$Menu.queue_free()
	$GameCode.queue_free()
	$WaitingLabel.queue_free()

func _on_game_disconnected():
	player.queue_free()
	other_player.queue_free()

	$GameCode.hide()
	$Menu.show()

func _on_game_info(game):
	$GameCode.text = "Game Code: %s" % game
	if MultiplayerClient.hosting:
		$WaitingLabel.text = 'Waiting for player...'
	$GameCode.show()

func _on_HostButton_pressed():
	OnlineGame.host(signal_server_url)
	$WaitingLabel.text = 'Waiting for server response...'
	$WaitingLabel.show()
	$Menu.hide()

func _on_JoinButton_pressed():
	OnlineGame.join(signal_server_url, $Menu/VBoxContainer/GameCode.text)
	$WaitingLabel.text = 'Joining ' + $Menu/VBoxContainer/GameCode.text
	$WaitingLabel.show()
	$Menu.hide()
